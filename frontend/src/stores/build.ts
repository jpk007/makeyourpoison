import { defineStore } from 'pinia'
import { ref } from 'vue'
import { startBuild, getBuildStatus } from '../api/client.js'
import { useConfigStore } from './config.js'

type BuildStatusValue = 'idle' | 'waiting' | 'active' | 'completed' | 'failed' | 'delayed'

export const useBuildStore = defineStore('build', () => {
  const jobId = ref<string | null>(null)
  const status = ref<BuildStatusValue>('idle')
  const progress = ref(0)
  const logs = ref<string[]>([])
  const error = ref<string | null>(null)
  const isStarting = ref(false)
  const downloadReady = ref(false)

  function reset(): void {
    jobId.value = null
    status.value = 'idle'
    progress.value = 0
    logs.value = []
    error.value = null
    isStarting.value = false
    downloadReady.value = false
  }

  function appendLog(line: string): void {
    logs.value.push(line)
  }

  function setProgress(pct: number): void {
    progress.value = pct
  }

  function setStatus(s: BuildStatusValue): void {
    status.value = s
  }

  async function triggerBuild(): Promise<string | null> {
    const configStore = useConfigStore()

    isStarting.value = true
    error.value = null

    try {
      // Ensure config is saved first
      let configId = configStore.savedConfigId
      if (!configId) {
        configId = await configStore.persistConfig()
      }
      if (!configId) {
        error.value = configStore.saveError ?? 'Could not save configuration.'
        return null
      }

      const response = await startBuild(configId)
      jobId.value = response.jobId
      status.value = 'waiting'
      logs.value = []
      progress.value = 0
      return response.jobId
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Failed to start build.'
      status.value = 'failed'
      return null
    } finally {
      isStarting.value = false
    }
  }

  async function pollStatus(): Promise<void> {
    if (!jobId.value) return
    try {
      const data = await getBuildStatus(jobId.value)
      status.value = data.status as BuildStatusValue
      progress.value = data.progress
      if (data.status === 'completed') {
        downloadReady.value = true
      }
    } catch (err) {
      console.error('[Build] Poll error:', err)
    }
  }

  return {
    jobId,
    status,
    progress,
    logs,
    error,
    isStarting,
    downloadReady,
    reset,
    appendLog,
    setProgress,
    setStatus,
    triggerBuild,
    pollStatus,
  }
})
