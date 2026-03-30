import { Pool } from 'pg'

const {
  PGHOST = 'localhost',
  PGPORT = '5432',
  PGUSER = 'postgres',
  PGPASSWORD = 'postgres',
  PGDATABASE = 'distroforge',
} = process.env

async function ensureDatabase(): Promise<void> {
  const admin = new Pool({ host: PGHOST, port: parseInt(PGPORT), user: PGUSER, password: PGPASSWORD, database: 'postgres' })
  try {
    await admin.query(`CREATE DATABASE "${PGDATABASE}"`)
  } catch (err: unknown) {
    if ((err as NodeJS.ErrnoException & { code?: string }).code !== '42P04') throw err // 42P04 = already exists
  } finally {
    await admin.end()
  }
}

export let pool: Pool

export async function initDb(): Promise<void> {
  await ensureDatabase()

  pool = new Pool({
    host: PGHOST,
    port: parseInt(PGPORT),
    user: PGUSER,
    password: PGPASSWORD,
    database: PGDATABASE,
    max: 10,
  })

  await pool.query(`
    CREATE TABLE IF NOT EXISTS configs (
      id UUID PRIMARY KEY,
      data JSONB NOT NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS jobs (
      id TEXT PRIMARY KEY,
      config_id UUID REFERENCES configs(id),
      status TEXT NOT NULL DEFAULT 'waiting',
      progress INTEGER NOT NULL DEFAULT 0,
      iso_path TEXT,
      base TEXT,
      desktop TEXT,
      error TEXT,
      logs TEXT[] NOT NULL DEFAULT '{}',
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
    ALTER TABLE jobs ADD COLUMN IF NOT EXISTS logs TEXT[] NOT NULL DEFAULT '{}';
  `)

  console.log('[DB] PostgreSQL connected and schema ready')
}
