import { WebSocketServer, WebSocket } from 'ws'
import { IncomingMessage, Server } from 'http'
import { WsFrame } from '@distroforge/shared'

// Map of jobId → set of connected WebSocket clients
const clients = new Map<string, Set<WebSocket>>()

function parseJobId(url: string | undefined): string | null {
  if (!url) return null
  // Expect path: /ws/build/:jobId
  const match = url.match(/\/ws\/build\/([^/?#]+)/)
  return match ? match[1] : null
}

export function attachWebSocketServer(server: Server): void {
  const wss = new WebSocketServer({ server })

  wss.on('connection', (ws: WebSocket, req: IncomingMessage) => {
    const jobId = parseJobId(req.url)
    if (!jobId) {
      ws.close(1008, 'Missing jobId in URL')
      return
    }

    if (!clients.has(jobId)) {
      clients.set(jobId, new Set())
    }
    clients.get(jobId)!.add(ws)

    ws.on('close', () => {
      const set = clients.get(jobId)
      if (set) {
        set.delete(ws)
        if (set.size === 0) clients.delete(jobId)
      }
    })

    ws.on('error', (err) => {
      console.error(`[WS] error for job ${jobId}:`, err.message)
    })
  })

  console.log('[WS] WebSocket server attached at /ws/build/:jobId')
}

export const buildSocketService = {
  sendFrame(jobId: string, frame: WsFrame): void {
    const set = clients.get(jobId)
    if (!set || set.size === 0) return
    const payload = JSON.stringify(frame)
    for (const ws of set) {
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(payload)
      }
    }
  },
}
