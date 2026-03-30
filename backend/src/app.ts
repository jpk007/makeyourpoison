import 'dotenv/config'
import express from 'express'
import cors from 'cors'
import http from 'http'
import configRoutes from './routes/config.routes'
import buildRoutes from './routes/build.routes'
import packagesRoutes from './routes/packages.routes'
import pingRoutes from './routes/ping.routes'
import { errorHandler } from './middleware/errorHandler'
import { attachWebSocketServer } from './ws/buildSocket'
import { initDb } from './db'

const app = express()
const PORT = parseInt(process.env.PORT ?? '3000', 10)

// ─── Middleware ───────────────────────────────────────────────────────────
app.use(cors({
  origin: process.env.NODE_ENV === 'production'
    ? process.env.CORS_ORIGIN ?? false
    : true,
  credentials: true,
}))
app.use(express.json({ limit: '1mb' }))
app.use(express.urlencoded({ extended: true }))

// ─── Routes ──────────────────────────────────────────────────────────────
app.use('/api/config', configRoutes)
app.use('/api/build', buildRoutes)
app.use('/api/packages', packagesRoutes)
app.use('/api/ping', pingRoutes)

// ─── 404 ─────────────────────────────────────────────────────────────────
app.use((_req, res) => {
  res.status(404).json({ error: 'Not found' })
})

// ─── Error handler ────────────────────────────────────────────────────────
app.use(errorHandler)

// ─── HTTP + WS server ─────────────────────────────────────────────────────
const server = http.createServer(app)
attachWebSocketServer(server)

initDb().then(() => {
  server.listen(PORT, () => {
    console.log(`[DistroForge] Backend listening on http://localhost:${PORT}`)
    console.log(`[DistroForge] WebSocket at ws://localhost:${PORT}/ws/build/:jobId`)
  })
}).catch((err) => {
  console.error('[DB] Failed to initialise database:', err)
  process.exit(1)
})

export default app
