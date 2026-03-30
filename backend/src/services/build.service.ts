import Bull from 'bull'
import { v4 as uuidv4 } from 'uuid'
import { spawn } from 'child_process'
import fs from 'fs'
import path from 'path'
import { Response } from 'express'
import { StartBuildRequest, BuildStatus, JobRecord } from '@distroforge/shared'
import { createError } from '../middleware/errorHandler'
import { configService } from './config.service'
import { buildSocketService } from '../ws/buildSocket'
import { pool } from '../db'

const REDIS_HOST = process.env.REDIS_HOST ?? 'localhost'
const REDIS_PORT = parseInt(process.env.REDIS_PORT ?? '6379', 10)
const BUILD_OUTPUT_PATH = process.env.BUILD_OUTPUT_PATH ?? '/tmp/distroforge-builds'
const MAX_CONCURRENT = parseInt(process.env.MAX_CONCURRENT_BUILDS ?? '2', 10)
const DOCKER_IMAGE = process.env.DOCKER_IMAGE ?? 'makeyourpoison-builder:latest'

export const buildQueue = new Bull<{ configId: string }>('iso-builds', {
  redis: { host: REDIS_HOST, port: REDIS_PORT },
})

// ─── DB helpers ───────────────────────────────────────────────────────────

async function dbInsertJob(jobId: string, configId: string, base: string, desktop: string): Promise<void> {
  await pool.query(
    `INSERT INTO jobs (id, config_id, status, progress, base, desktop)
     VALUES ($1, $2, 'waiting', 0, $3, $4)
     ON CONFLICT (id) DO NOTHING`,
    [jobId, configId, base, desktop]
  )
}

async function dbUpdateJob(jobId: string, fields: Partial<{ status: string; progress: number; iso_path: string; error: string }>): Promise<void> {
  const sets: string[] = ['updated_at = NOW()']
  const values: unknown[] = []
  let i = 1
  for (const [key, val] of Object.entries(fields)) {
    sets.push(`${key} = $${i}`)
    values.push(val)
    i++
  }
  values.push(jobId)
  await pool.query(`UPDATE jobs SET ${sets.join(', ')} WHERE id = $${i}`, values)
}

async function dbAppendLog(jobId: string, line: string): Promise<void> {
  await pool.query(
    `UPDATE jobs SET logs = array_append(logs, $1), updated_at = NOW() WHERE id = $2`,
    [line, jobId]
  )
}

// ─── Bull processor ───────────────────────────────────────────────────────

buildQueue.process(MAX_CONCURRENT, async (job) => {
  const { configId } = job.data
  const config = await configService.findById(configId)
  if (!config) throw new Error(`Config ${configId} not found`)

  const outputDir = path.join(BUILD_OUTPUT_PATH, job.id.toString())
  fs.mkdirSync(outputDir, { recursive: true })

  await dbUpdateJob(job.id.toString(), { status: 'active' })

  return new Promise<{ isoPath: string }>((resolve, reject) => {
    const packages = config.packages.join(',')
    const bundles = config.appBundles.join(',')

    const dockerArgs = [
      'run', '--rm', '--privileged',
      '-e', `BUILD_DESKTOP=${config.desktop}`,
      '-e', `BUILD_KERNEL=${config.kernel}`,
      '-e', `BUILD_PACKAGES=${packages}`,
      '-e', `BUILD_APP_BUNDLES=${bundles}`,
      '-e', `BUILD_LOCALE_TIMEZONE=${config.locale.timezone}`,
      '-e', `BUILD_LOCALE_LANGUAGE=${config.locale.language}`,
      '-e', `BUILD_LOCALE_KEYBOARD=${config.locale.keyboard}`,
      '-e', `BUILD_GRUB_THEME=${config.boot.grubTheme}`,
      '-e', `BUILD_SPLASH_SCREEN=${config.boot.splashScreen}`,
      '-e', `BUILD_GRUB_TIMEOUT=${config.boot.timeout}`,
      '-e', `BUILD_ISO_NAME=${config.isoName ?? 'makeyourpoison'}`,
      '-e', `OUTPUT_DIR=/output`,
      '-v', `${outputDir}:/output`,
      DOCKER_IMAGE,
    ]

    const proc = spawn('docker', dockerArgs, { stdio: ['ignore', 'pipe', 'pipe'] })

    const handleLine = (line: string): void => {
      const m = line.match(/^PROGRESS:(\d+):(.*)$/)
      if (m) {
        const percent = parseInt(m[1], 10)
        const msg = m[2].trim()
        buildSocketService.sendFrame(job.id.toString(), { type: 'progress', percent })
        if (msg) {
          buildSocketService.sendFrame(job.id.toString(), { type: 'log', line: msg })
          dbAppendLog(job.id.toString(), msg).catch(() => undefined)
        }
        job.progress(percent).catch(() => undefined)
        dbUpdateJob(job.id.toString(), { progress: percent }).catch(() => undefined)
      } else if (line.trim()) {
        buildSocketService.sendFrame(job.id.toString(), { type: 'log', line })
        dbAppendLog(job.id.toString(), line).catch(() => undefined)
      }
    }

    let stdoutBuf = ''
    proc.stdout.on('data', (chunk: Buffer) => {
      stdoutBuf += chunk.toString()
      const lines = stdoutBuf.split('\n')
      stdoutBuf = lines.pop() ?? ''
      for (const line of lines) handleLine(line)
    })

    let stderrBuf = ''
    proc.stderr.on('data', (chunk: Buffer) => {
      stderrBuf += chunk.toString()
      const lines = stderrBuf.split('\n')
      stderrBuf = lines.pop() ?? ''
      for (const line of lines) {
        if (line.trim()) {
          const errLine = `[stderr] ${line}`
          buildSocketService.sendFrame(job.id.toString(), { type: 'log', line: errLine })
          dbAppendLog(job.id.toString(), errLine).catch(() => undefined)
        }
      }
    })

    proc.on('close', async (code) => {
      if (stdoutBuf.trim()) handleLine(stdoutBuf)
      if (stderrBuf.trim()) buildSocketService.sendFrame(job.id.toString(), { type: 'log', line: `[stderr] ${stderrBuf}` })

      if (code === 0) {
        const isoFiles = fs.existsSync(outputDir)
          ? fs.readdirSync(outputDir).filter(f => f.endsWith('.iso'))
          : []
        if (isoFiles.length > 0) {
          const isoPath = path.join(outputDir, isoFiles[0])
          await dbUpdateJob(job.id.toString(), { status: 'completed', progress: 100, iso_path: isoPath })
          buildSocketService.sendFrame(job.id.toString(), { type: 'complete', isoPath })
          resolve({ isoPath })
        } else {
          const err = new Error('Build completed but no ISO file found in output directory')
          await dbUpdateJob(job.id.toString(), { status: 'failed', error: err.message })
          buildSocketService.sendFrame(job.id.toString(), { type: 'error', message: err.message })
          reject(err)
        }
      } else {
        const errMsg = `Docker container exited with code ${code}`
        await dbUpdateJob(job.id.toString(), { status: 'failed', error: errMsg })
        buildSocketService.sendFrame(job.id.toString(), { type: 'error', message: errMsg })
        reject(new Error(errMsg))
      }
    })

    proc.on('error', async (err) => {
      const msg = err.message.includes('ENOENT')
        ? 'Docker not found. Make sure Docker is installed and running.'
        : err.message
      await dbUpdateJob(job.id.toString(), { status: 'failed', error: msg })
      buildSocketService.sendFrame(job.id.toString(), { type: 'error', message: msg })
      reject(new Error(msg))
    })
  })
})

buildQueue.on('failed', (job, err) => {
  buildSocketService.sendFrame(job.id.toString(), { type: 'error', message: err.message })
  dbUpdateJob(job.id.toString(), { status: 'failed', error: err.message }).catch(() => undefined)
})

// ─── Service API ──────────────────────────────────────────────────────────

export const buildService = {
  async queueBuild(body: StartBuildRequest): Promise<{ jobId: string }> {
    const [active, waiting] = await Promise.all([
      buildQueue.getActiveCount(),
      buildQueue.getWaitingCount(),
    ])
    if (active + waiting >= MAX_CONCURRENT * 2) {
      throw createError('Too many builds queued. Try again later.', 429)
    }

    // Look up config to get base/desktop for the jobs table
    const config = await configService.findById(body.configId)
    if (!config) throw createError('Config not found', 404)

    const job = await buildQueue.add({ configId: body.configId }, { jobId: uuidv4() })
    await dbInsertJob(job.id.toString(), body.configId, config.base, config.desktop)
    return { jobId: job.id.toString() }
  },

  async getStatus(jobId: string): Promise<BuildStatus> {
    const result = await pool.query<{ status: string; progress: number; logs: string[] }>(
      'SELECT status, progress, logs FROM jobs WHERE id = $1',
      [jobId]
    )
    if (result.rows.length === 0) throw createError(`Job ${jobId} not found`, 404)
    const { status, progress, logs } = result.rows[0]
    return { status: status as BuildStatus['status'], progress, logs: logs ?? [] }
  },

  async getJobs(limit = 50, offset = 0): Promise<{ jobs: JobRecord[]; total: number }> {
    const [rows, countRow] = await Promise.all([
      pool.query<{
        id: string; config_id: string; status: string; progress: number;
        iso_path: string | null; base: string | null; desktop: string | null;
        error: string | null; logs: string[]; created_at: Date; updated_at: Date;
      }>(
        `SELECT id, config_id, status, progress, iso_path, base, desktop, error, logs, created_at, updated_at
         FROM jobs ORDER BY created_at DESC LIMIT $1 OFFSET $2`,
        [limit, offset]
      ),
      pool.query<{ count: string }>('SELECT COUNT(*) as count FROM jobs'),
    ])

    const jobs: JobRecord[] = rows.rows.map(r => ({
      id: r.id,
      configId: r.config_id,
      status: r.status as JobRecord['status'],
      progress: r.progress,
      isoPath: r.iso_path,
      base: r.base,
      desktop: r.desktop,
      error: r.error,
      logs: r.logs ?? [],
      createdAt: r.created_at.toISOString(),
      updatedAt: r.updated_at.toISOString(),
    }))

    return { jobs, total: parseInt(countRow.rows[0].count, 10) }
  },

  async streamDownload(jobId: string, res: Response): Promise<void> {
    const result = await pool.query<{ iso_path: string | null; status: string }>(
      'SELECT iso_path, status FROM jobs WHERE id = $1',
      [jobId]
    )
    if (result.rows.length === 0) throw createError(`Job ${jobId} not found`, 404)
    const { status, iso_path: isoPath } = result.rows[0]
    if (status !== 'completed') throw createError('Build is not yet complete', 400)
    if (!isoPath || !fs.existsSync(isoPath)) throw createError('ISO file not found', 404)

    const stat = fs.statSync(isoPath)
    const filename = path.basename(isoPath)

    res.setHeader('Content-Type', 'application/octet-stream')
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`)
    res.setHeader('Content-Length', stat.size.toString())

    const stream = fs.createReadStream(isoPath, { highWaterMark: 64 * 1024 })
    stream.pipe(res)
    await new Promise<void>((resolve, reject) => {
      stream.on('end', resolve)
      stream.on('error', reject)
    })
  },
}
