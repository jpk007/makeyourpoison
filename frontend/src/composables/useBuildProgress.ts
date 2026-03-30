import { ref, onUnmounted } from 'vue'
import type { WsFrame } from '@distroforge/shared'

export function useBuildProgress(jobId: string) {
  const progress = ref(0)
  const logs = ref<string[]>([])
  const status = ref<'idle' | 'building' | 'done' | 'failed'>('idle')
  const wsUrl = `${import.meta.env.VITE_WS_URL ?? 'ws://localhost:3000/ws'}/build/${jobId}`

  status.value = 'building'

  const ws = new WebSocket(wsUrl)

  ws.onopen = () => {
    logs.value.push('[Connected to build stream]')
  }

  ws.onmessage = ({ data }: MessageEvent<string>) => {
    const frame = JSON.parse(data) as WsFrame
    if (frame.type === 'log') logs.value = [...logs.value, frame.line]
    if (frame.type === 'progress') progress.value = frame.percent
    if (frame.type === 'complete') status.value = 'done'
    if (frame.type === 'error') {
      status.value = 'failed'
      logs.value.push(`[Error] ${frame.message}`)
    }
  }

  ws.onerror = () => {
    logs.value.push('[WebSocket error — falling back to polling]')
  }

  ws.onclose = (event) => {
    if (status.value === 'building') {
      logs.value.push(`[Connection closed (${event.code})]`)
    }
  }

  onUnmounted(() => {
    ws.close()
  })

  return { progress, logs, status }
}
