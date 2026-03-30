<template>
  <WizardShell
    title="Build Your ISO"
    subtitle="Your custom Linux distro is ready to be built. This will take a few minutes."
  >
    <!-- Pre-build state -->
    <div v-if="buildStore.status === 'idle'" class="space-y-6">
      <div class="rounded-xl border border-brand-700/40 bg-brand-950/20 p-6 text-center">
        <span class="text-5xl block mb-4">🔨</span>
        <h2 class="text-xl font-bold text-white mb-2">Ready to Forge</h2>
        <p class="text-slate-400 text-sm max-w-md mx-auto">
          Your configuration has been saved. Click the button below to queue the ISO build.
          You'll see live progress streamed from the build server.
        </p>
        <button
          type="button"
          :disabled="buildStore.isStarting || configStore.isSaving"
          :class="[
            'mt-6 inline-flex items-center gap-2 rounded-xl px-8 py-3.5 text-base font-semibold transition-all focus:outline-none focus-visible:ring-2 focus-visible:ring-brand-400',
            buildStore.isStarting || configStore.isSaving
              ? 'bg-slate-700 text-slate-400 cursor-not-allowed'
              : 'bg-brand-600 text-white hover:bg-brand-500 shadow-xl shadow-brand-900/50',
          ]"
          @click="startBuild"
        >
          <span v-if="buildStore.isStarting || configStore.isSaving" class="h-4 w-4 rounded-full border-2 border-white/30 border-t-white animate-spin" />
          <svg v-else class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
            <path d="M6.3 2.841A1.5 1.5 0 004 4.11V15.89a1.5 1.5 0 002.3 1.269l9.344-5.89a1.5 1.5 0 000-2.538L6.3 2.84z" />
          </svg>
          {{ buildStore.isStarting || configStore.isSaving ? 'Starting...' : 'Start Build' }}
        </button>
      </div>

      <div v-if="buildStore.error" class="rounded-lg border border-red-800 bg-red-950/30 p-4 text-sm text-red-400">
        {{ buildStore.error }}
      </div>
    </div>

    <!-- Building / active -->
    <div v-else class="space-y-4">
      <!-- Status header -->
      <div class="rounded-xl border border-slate-800 bg-slate-900/60 p-4 flex items-center gap-4">
        <div class="flex-1">
          <div class="flex items-center justify-between mb-2">
            <span class="text-sm font-medium text-slate-300">
              <span v-if="wsStatus === 'building'" class="flex items-center gap-2">
                <span class="h-2 w-2 rounded-full bg-brand-400 animate-pulse" />
                Building...
              </span>
              <span v-else-if="wsStatus === 'done'" class="flex items-center gap-2 text-emerald-400">
                <span class="h-2 w-2 rounded-full bg-emerald-400" />
                Build Complete
              </span>
              <span v-else-if="wsStatus === 'failed'" class="flex items-center gap-2 text-red-400">
                <span class="h-2 w-2 rounded-full bg-red-400" />
                Build Failed
              </span>
            </span>
            <span class="text-sm font-mono font-semibold text-brand-300">{{ wsProgress }}%</span>
          </div>
          <div class="h-2 w-full rounded-full bg-slate-800 overflow-hidden">
            <div
              :class="[
                'h-full rounded-full transition-all duration-500',
                wsStatus === 'done' ? 'bg-emerald-500' :
                wsStatus === 'failed' ? 'bg-red-500' :
                'bg-brand-500',
              ]"
              :style="{ width: wsProgress + '%' }"
            />
          </div>
        </div>
      </div>

      <!-- Job ID -->
      <div v-if="buildStore.jobId" class="flex items-center gap-2 text-xs text-slate-500 font-mono">
        <span>Job ID:</span>
        <span class="text-slate-400">{{ buildStore.jobId }}</span>
      </div>

      <!-- Log output -->
      <div class="rounded-xl border border-slate-800 bg-slate-950 overflow-hidden">
        <div class="flex items-center justify-between border-b border-slate-800 px-4 py-2">
          <span class="text-xs font-mono text-slate-400">Build Logs</span>
          <span class="text-xs text-slate-500">{{ wsLogs.length }} lines</span>
        </div>
        <div
          ref="logContainer"
          class="h-72 overflow-y-auto p-4 font-mono text-xs leading-relaxed space-y-0.5"
        >
          <div
            v-for="(line, i) in wsLogs"
            :key="i"
            :class="[
              line.startsWith('[Error]') ? 'text-red-400' :
              line.startsWith('[Connected') ? 'text-emerald-400' :
              line.startsWith('[') ? 'text-slate-500' :
              'text-slate-300',
            ]"
          >
            <span class="select-none text-slate-600 mr-2">{{ String(i + 1).padStart(3, '0') }}</span>{{ line }}
          </div>
          <div v-if="wsStatus === 'building'" class="text-brand-400 animate-pulse">▊</div>
        </div>
      </div>

      <!-- Download button -->
      <div v-if="wsStatus === 'done'" class="rounded-xl border border-emerald-700/50 bg-emerald-950/20 p-5 flex flex-col sm:flex-row items-center gap-4">
        <div class="flex-1">
          <h3 class="font-semibold text-emerald-400">ISO Ready for Download</h3>
          <p class="text-xs text-slate-400 mt-1">Your custom Linux ISO has been built successfully.</p>
        </div>
        <a
          :href="`${apiBase}/build/download/${buildStore.jobId}`"
          class="inline-flex items-center gap-2 rounded-lg bg-emerald-600 px-5 py-2.5 text-sm font-semibold text-white hover:bg-emerald-500 transition-colors"
          download
        >
          <svg class="h-4 w-4" viewBox="0 0 16 16" fill="none">
            <path d="M8 1v9m0 0l-3-3m3 3l3-3M1 12v2a1 1 0 001 1h12a1 1 0 001-1v-2" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" />
          </svg>
          Download ISO
        </a>
      </div>

      <!-- Error state -->
      <div v-if="wsStatus === 'failed'" class="rounded-xl border border-red-800 bg-red-950/20 p-5">
        <h3 class="font-semibold text-red-400 mb-2">Build Failed</h3>
        <p class="text-sm text-slate-400">Check the logs above for details. You can try starting a new build.</p>
        <button
          type="button"
          class="mt-3 rounded-lg bg-slate-800 px-4 py-2 text-sm text-slate-300 hover:bg-slate-700 transition-colors"
          @click="buildStore.reset()"
        >
          Try Again
        </button>
      </div>
    </div>
  </WizardShell>
</template>

<script setup lang="ts">
import { ref, watch, nextTick, computed } from 'vue'
import WizardShell from '../components/WizardShell.vue'
import { useConfigStore } from '../stores/config.js'
import { useBuildStore } from '../stores/build.js'
import { useBuildProgress } from '../composables/useBuildProgress.js'

const configStore = useConfigStore()
const buildStore = useBuildStore()
const logContainer = ref<HTMLElement | null>(null)
const apiBase = import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:3000/api'

// WebSocket progress composable — only active when we have a jobId
const wsProgress = ref(0)
const wsLogs = ref<string[]>([])
const wsStatus = ref<'idle' | 'building' | 'done' | 'failed'>('idle')
let activeProgress: ReturnType<typeof useBuildProgress> | null = null

watch(
  () => buildStore.jobId,
  (newJobId) => {
    if (!newJobId) return
    activeProgress = useBuildProgress(newJobId)
    // Sync reactive refs from composable
    watch(activeProgress.progress, (v) => {
      wsProgress.value = v
      buildStore.setProgress(v)
    }, { immediate: true })
    watch(activeProgress.logs, (v) => {
      wsLogs.value = [...v]
    }, { immediate: true, deep: true })
    watch(activeProgress.status, (v) => {
      wsStatus.value = v
      if (v === 'done') {
        buildStore.setStatus('completed')
        buildStore.downloadReady = true
      } else if (v === 'failed') {
        buildStore.setStatus('failed')
      }
    }, { immediate: true })
  }
)

// Track initial status from store for already-running builds
const combinedStatus = computed(() =>
  buildStore.jobId ? wsStatus.value : 'idle' as const
)

// Auto-scroll log container
watch(wsLogs, async () => {
  await nextTick()
  if (logContainer.value) {
    logContainer.value.scrollTop = logContainer.value.scrollHeight
  }
})

async function startBuild(): Promise<void> {
  wsProgress.value = 0
  wsLogs.value = []
  wsStatus.value = 'idle'
  await buildStore.triggerBuild()
}

// Expose computed for template
const _combinedStatus = combinedStatus
</script>
