<template>
  <div class="min-h-screen bg-slate-950">
    <!-- Header -->
    <header class="border-b border-slate-800 bg-slate-900/80 backdrop-blur sticky top-0 z-10">
      <div class="mx-auto max-w-5xl px-4 py-3 flex items-center justify-between">
        <div class="flex items-center gap-4">
          <RouterLink to="/step/1" class="text-xl font-bold text-brand-400 hover:text-brand-300 transition-colors">
            MakeYourPoison
          </RouterLink>
          <span class="text-slate-600">/</span>
          <span class="text-sm font-medium text-slate-300">Build Jobs</span>
        </div>
        <RouterLink
          to="/step/1"
          class="flex items-center gap-2 rounded-lg bg-brand-600 px-4 py-2 text-sm font-semibold text-white hover:bg-brand-500 transition-colors"
        >
          <svg class="h-4 w-4" viewBox="0 0 16 16" fill="none">
            <path d="M8 2v12M2 8h12" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
          </svg>
          New Build
        </RouterLink>
      </div>
    </header>

    <main class="mx-auto max-w-5xl px-4 py-8">
      <div class="flex items-center justify-between mb-6">
        <div>
          <h1 class="text-2xl font-bold text-white">Build Jobs</h1>
          <p class="text-slate-400 text-sm mt-1">{{ total }} total job{{ total !== 1 ? 's' : '' }}</p>
        </div>
        <button
          type="button"
          class="flex items-center gap-2 rounded-lg border border-slate-700 px-3 py-2 text-sm text-slate-300 hover:bg-slate-800 transition-colors"
          :class="{ 'opacity-50': isLoading }"
          @click="loadJobs"
        >
          <svg class="h-4 w-4" :class="{ 'animate-spin': isLoading }" viewBox="0 0 16 16" fill="none">
            <path d="M14 8A6 6 0 112 8" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
          </svg>
          Refresh
        </button>
      </div>

      <!-- Error state -->
      <div v-if="error" class="rounded-lg border border-red-800 bg-red-950/30 p-4 text-sm text-red-400 mb-4">
        {{ error }}
      </div>

      <!-- Empty state -->
      <div v-else-if="!isLoading && jobs.length === 0" class="rounded-xl border border-slate-800 bg-slate-900/40 p-12 text-center">
        <div class="text-4xl mb-3">🔨</div>
        <h2 class="text-lg font-semibold text-white mb-1">No builds yet</h2>
        <p class="text-slate-400 text-sm mb-4">Start your first ISO build from the wizard.</p>
        <RouterLink
          to="/step/1"
          class="inline-flex items-center gap-2 rounded-lg bg-brand-600 px-5 py-2.5 text-sm font-semibold text-white hover:bg-brand-500 transition-colors"
        >
          Start a Build
        </RouterLink>
      </div>

      <!-- Jobs table -->
      <div v-else class="rounded-xl border border-slate-800 overflow-hidden">
        <!-- Loading skeleton -->
        <template v-if="isLoading && jobs.length === 0">
          <div v-for="i in 3" :key="i" class="border-b border-slate-800 p-5 animate-pulse">
            <div class="flex items-center gap-4">
              <div class="h-8 w-8 rounded-full bg-slate-800" />
              <div class="flex-1 space-y-2">
                <div class="h-3 w-40 rounded bg-slate-800" />
                <div class="h-3 w-64 rounded bg-slate-800" />
              </div>
              <div class="h-6 w-20 rounded-full bg-slate-800" />
            </div>
          </div>
        </template>

        <template v-else>
          <div
            v-for="job in jobs"
            :key="job.id"
            class="border-b border-slate-800 last:border-0 p-5 hover:bg-slate-900/40 transition-colors"
          >
            <div class="flex items-start gap-4">
              <!-- Status icon -->
              <div
                :class="[
                  'mt-0.5 flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-full text-sm',
                  statusStyle(job.status).bg,
                ]"
              >
                <span v-if="job.status === 'active'" class="h-3 w-3 rounded-full bg-current animate-ping" />
                <svg v-else-if="job.status === 'completed'" class="h-4 w-4" viewBox="0 0 16 16" fill="none">
                  <path d="M3 8l4 4 6-7" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>
                <svg v-else-if="job.status === 'failed'" class="h-4 w-4" viewBox="0 0 16 16" fill="none">
                  <path d="M4 4l8 8M12 4l-8 8" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
                </svg>
                <svg v-else class="h-4 w-4" viewBox="0 0 16 16" fill="none">
                  <circle cx="8" cy="8" r="5" stroke="currentColor" stroke-width="1.5"/>
                  <path d="M8 5v3l2 2" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
                </svg>
              </div>

              <!-- Job details -->
              <div class="flex-1 min-w-0">
                <div class="flex items-center gap-3 flex-wrap">
                  <span class="font-mono text-sm font-semibold text-white">
                    {{ job.base ?? '?' }}-{{ job.desktop ?? '?' }}
                  </span>
                  <span
                    :class="[
                      'inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold capitalize',
                      statusStyle(job.status).badge,
                    ]"
                  >
                    {{ job.status }}
                  </span>
                  <span class="text-xs text-slate-500 font-mono">{{ job.id }}</span>
                </div>

                <!-- Progress bar for active/waiting -->
                <div v-if="job.status === 'active' || job.status === 'waiting'" class="mt-2 flex items-center gap-2">
                  <div class="flex-1 h-1.5 rounded-full bg-slate-800 overflow-hidden max-w-xs">
                    <div
                      class="h-full rounded-full bg-brand-500 transition-all duration-500"
                      :style="{ width: job.progress + '%' }"
                    />
                  </div>
                  <span class="text-xs text-slate-400 font-mono tabular-nums">{{ job.progress }}%</span>
                </div>

                <!-- Error message -->
                <p v-if="job.error" class="mt-1 text-xs text-red-400 truncate">{{ job.error }}</p>

                <p class="mt-1 text-xs text-slate-500">
                  Started {{ formatDate(job.createdAt) }}
                </p>
              </div>

              <!-- Actions -->
              <div class="flex items-center gap-2 flex-shrink-0">
                <button
                  v-if="job.logs.length > 0"
                  type="button"
                  class="flex items-center gap-1.5 rounded-lg border border-slate-700 px-3 py-1.5 text-xs font-medium text-slate-400 hover:text-white hover:bg-slate-800 transition-colors"
                  @click="toggleLogs(job.id)"
                >
                  <svg class="h-3.5 w-3.5 transition-transform" :class="{ 'rotate-180': expandedJob === job.id }" viewBox="0 0 14 14" fill="none">
                    <path d="M3 5l4 4 4-4" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
                  </svg>
                  Logs
                </button>
                <a
                  v-if="job.status === 'completed'"
                  :href="`${apiBase}/build/download/${job.id}`"
                  class="flex items-center gap-1.5 rounded-lg bg-emerald-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-emerald-500 transition-colors"
                  download
                >
                  <svg class="h-3.5 w-3.5" viewBox="0 0 14 14" fill="none">
                    <path d="M7 1v8M7 9l-3-3m3 3l3-3M1 11v1a1 1 0 001 1h10a1 1 0 001-1v-1" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
                  </svg>
                  Download
                </a>
              </div>
            </div>

            <!-- Log drawer -->
            <div v-if="expandedJob === job.id && job.logs.length > 0" class="mt-3 rounded-lg border border-slate-800 bg-slate-950 overflow-hidden">
              <div class="flex items-center justify-between border-b border-slate-800 px-3 py-2">
                <span class="text-xs font-mono text-slate-400">Build Logs — {{ job.logs.length }} lines</span>
              </div>
              <div class="h-56 overflow-y-auto p-3 font-mono text-xs leading-relaxed space-y-0.5">
                <div
                  v-for="(line, i) in job.logs"
                  :key="i"
                  :class="[
                    line.startsWith('[stderr]') ? 'text-red-400' :
                    line.startsWith('PROGRESS') ? 'text-brand-400' :
                    'text-slate-300'
                  ]"
                >
                  <span class="select-none text-slate-600 mr-2">{{ String(i + 1).padStart(3, '0') }}</span>{{ line }}
                </div>
              </div>
            </div>
          </div>
        </template>
      </div>

      <!-- Pagination -->
      <div v-if="total > pageSize" class="flex items-center justify-between mt-4">
        <p class="text-xs text-slate-500">
          Showing {{ offset + 1 }}–{{ Math.min(offset + jobs.length, total) }} of {{ total }}
        </p>
        <div class="flex gap-2">
          <button
            type="button"
            :disabled="offset === 0"
            class="rounded-lg border border-slate-700 px-3 py-1.5 text-sm text-slate-300 hover:bg-slate-800 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
            @click="prevPage"
          >
            Previous
          </button>
          <button
            type="button"
            :disabled="offset + pageSize >= total"
            class="rounded-lg border border-slate-700 px-3 py-1.5 text-sm text-slate-300 hover:bg-slate-800 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
            @click="nextPage"
          >
            Next
          </button>
        </div>
      </div>
    </main>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { RouterLink } from 'vue-router'
import type { JobRecord } from '@distroforge/shared'
import { getJobs } from '../api/client'

const apiBase = import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:3000/api'

const jobs = ref<JobRecord[]>([])
const total = ref(0)
const isLoading = ref(false)
const error = ref<string | null>(null)
const pageSize = 20
const offset = ref(0)
const expandedJob = ref<string | null>(null)

function toggleLogs(jobId: string): void {
  expandedJob.value = expandedJob.value === jobId ? null : jobId
}

async function loadJobs(): Promise<void> {
  isLoading.value = true
  error.value = null
  try {
    const data = await getJobs(pageSize, offset.value)
    jobs.value = data.jobs
    total.value = data.total
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Failed to load jobs'
  } finally {
    isLoading.value = false
  }
}

function nextPage(): void {
  offset.value += pageSize
  loadJobs()
}

function prevPage(): void {
  offset.value = Math.max(0, offset.value - pageSize)
  loadJobs()
}

function statusStyle(status: string): { bg: string; badge: string } {
  switch (status) {
    case 'completed': return { bg: 'bg-emerald-500/20 text-emerald-400', badge: 'bg-emerald-500/20 text-emerald-300' }
    case 'active':    return { bg: 'bg-brand-500/20 text-brand-400',     badge: 'bg-brand-500/20 text-brand-300' }
    case 'failed':    return { bg: 'bg-red-500/20 text-red-400',         badge: 'bg-red-500/20 text-red-300' }
    case 'waiting':   return { bg: 'bg-amber-500/20 text-amber-400',     badge: 'bg-amber-500/20 text-amber-300' }
    default:          return { bg: 'bg-slate-700 text-slate-400',        badge: 'bg-slate-700 text-slate-300' }
  }
}

function formatDate(iso: string): string {
  return new Intl.DateTimeFormat(undefined, {
    month: 'short', day: 'numeric',
    hour: '2-digit', minute: '2-digit',
  }).format(new Date(iso))
}

// Auto-refresh every 5s when there are active jobs
let timer: ReturnType<typeof setInterval> | null = null

function maybeStartPolling(): void {
  const hasActive = jobs.value.some(j => j.status === 'active' || j.status === 'waiting')
  if (hasActive && !timer) {
    timer = setInterval(loadJobs, 5000)
  } else if (!hasActive && timer) {
    clearInterval(timer)
    timer = null
  }
}

onMounted(async () => {
  await loadJobs()
  maybeStartPolling()
})

onUnmounted(() => {
  if (timer) clearInterval(timer)
})
</script>
