import { Router } from 'express'
import { StartBuildSchema } from '@distroforge/shared'
import { validate } from '../middleware/validate'
import { buildService } from '../services/build.service'

const router = Router()

router.post('/start', validate(StartBuildSchema), async (req, res, next) => {
  try {
    const result = await buildService.queueBuild(req.body)
    res.status(202).json(result)
  } catch (err) {
    next(err)
  }
})

router.get('/status/:jobId', async (req, res, next) => {
  try {
    const status = await buildService.getStatus(req.params.jobId)
    res.json(status)
  } catch (err) {
    next(err)
  }
})

router.get('/download/:jobId', async (req, res, next) => {
  try {
    await buildService.streamDownload(req.params.jobId, res)
  } catch (err) {
    next(err)
  }
})

router.get('/jobs', async (req, res, next) => {
  try {
    const limit = Math.min(parseInt((req.query.limit as string) ?? '50', 10), 100)
    const offset = parseInt((req.query.offset as string) ?? '0', 10)
    const result = await buildService.getJobs(limit, offset)
    res.json(result)
  } catch (err) {
    next(err)
  }
})

export default router
