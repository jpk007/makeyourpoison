import { v4 as uuidv4 } from 'uuid'
import { pool } from '../db'
import { DistroConfig } from '@distroforge/shared'

export const configService = {
  async save(config: DistroConfig): Promise<{ configId: string }> {
    const configId = uuidv4()
    await pool.query(
      'INSERT INTO configs (id, data) VALUES ($1, $2)',
      [configId, JSON.stringify(config)]
    )
    return { configId }
  },

  async findById(configId: string): Promise<DistroConfig | null> {
    const result = await pool.query<{ data: DistroConfig }>(
      'SELECT data FROM configs WHERE id = $1',
      [configId]
    )
    if (result.rows.length === 0) return null
    return result.rows[0].data as DistroConfig
  },
}
