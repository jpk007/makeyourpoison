<template>
  <div class="min-h-screen bg-slate-950 flex flex-col">
    <!-- Header -->
    <header class="border-b border-slate-800 bg-slate-900/80 backdrop-blur sticky top-0 z-10">
      <div class="mx-auto max-w-5xl px-4 py-3 flex items-center justify-between">
        <div class="flex items-center gap-3">
          <span class="text-xl font-bold text-brand-400">MakeYourPoison</span>
          <span class="hidden sm:block text-xs text-slate-500 font-mono">
            Step {{ currentStep }} / {{ totalSteps }}
          </span>
        </div>
        <div class="flex items-center gap-4">
          <RouterLink
            to="/jobs"
            class="hidden sm:flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-xs font-medium text-slate-400 hover:text-white hover:bg-slate-800 transition-colors"
          >
            <svg class="h-3.5 w-3.5" viewBox="0 0 14 14" fill="none">
              <rect x="1" y="1" width="12" height="12" rx="2" stroke="currentColor" stroke-width="1.5"/>
              <path d="M4 5h6M4 7.5h4" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
            </svg>
            Jobs
          </RouterLink>
          <span class="text-sm text-slate-400 font-medium">{{ stepTitle }}</span>
        </div>
      </div>
    </header>

    <!-- Step indicator -->
    <div class="bg-slate-900/40 border-b border-slate-800">
      <div class="mx-auto max-w-5xl px-4 py-3">
        <div class="flex items-center gap-1">
          <template v-for="n in totalSteps" :key="n">
            <button
              type="button"
              :title="stepTitles[n - 1]"
              :class="[
                'flex h-7 w-7 items-center justify-center rounded-full text-xs font-semibold transition-all focus:outline-none focus-visible:ring-2 focus-visible:ring-brand-400',
                n === currentStep
                  ? 'bg-brand-500 text-white shadow shadow-brand-500/50'
                  : n < currentStep
                  ? 'bg-brand-900 text-brand-300 cursor-pointer hover:bg-brand-800'
                  : 'bg-slate-800 text-slate-500 cursor-default',
              ]"
              @click="n < currentStep ? goTo(n) : undefined"
            >
              <svg v-if="n < currentStep" class="h-3.5 w-3.5" viewBox="0 0 14 14" fill="none">
                <path d="M2.5 7l3.5 3.5 5.5-6" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
              </svg>
              <span v-else>{{ n }}</span>
            </button>
            <div
              v-if="n < totalSteps"
              :class="[
                'h-0.5 flex-1 rounded transition-colors',
                n < currentStep ? 'bg-brand-700' : 'bg-slate-800',
              ]"
            />
          </template>
        </div>
      </div>
    </div>

    <!-- Main content -->
    <main class="mx-auto w-full max-w-5xl flex-1 px-4 py-8">
      <div class="mb-6">
        <h1 class="text-2xl font-bold text-white">{{ title }}</h1>
        <p v-if="subtitle" class="mt-1 text-slate-400">{{ subtitle }}</p>
      </div>

      <slot />
    </main>

    <!-- Footer nav -->
    <footer class="sticky bottom-0 border-t border-slate-800 bg-slate-900/90 backdrop-blur">
      <div class="mx-auto max-w-5xl px-4 py-4 flex items-center justify-between gap-4">
        <button
          v-if="currentStep > 1"
          type="button"
          class="flex items-center gap-2 rounded-lg px-5 py-2.5 text-sm font-medium text-slate-300 hover:text-white hover:bg-slate-800 transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-brand-400"
          @click="prev"
        >
          <svg class="h-4 w-4" viewBox="0 0 16 16" fill="none">
            <path d="M10 12L6 8l4-4" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
          </svg>
          Back
        </button>
        <div v-else class="w-20" />

        <!-- Progress bar in footer -->
        <div class="flex-1 max-w-xs">
          <div class="h-1.5 rounded-full bg-slate-800 overflow-hidden">
            <div
              class="h-full rounded-full bg-brand-500 transition-all duration-500"
              :style="{ width: `${(currentStep / totalSteps) * 100}%` }"
            />
          </div>
        </div>

        <button
          v-if="currentStep < totalSteps"
          type="button"
          :disabled="!canProceed"
          :class="[
            'flex items-center gap-2 rounded-lg px-5 py-2.5 text-sm font-semibold transition-all focus:outline-none focus-visible:ring-2 focus-visible:ring-brand-400',
            canProceed
              ? 'bg-brand-600 text-white hover:bg-brand-500 shadow-lg shadow-brand-900/40'
              : 'bg-slate-800 text-slate-500 cursor-not-allowed',
          ]"
          @click="next"
        >
          {{ currentStep === 7 ? 'Start Build' : 'Continue' }}
          <svg class="h-4 w-4" viewBox="0 0 16 16" fill="none">
            <path d="M6 4l4 4-4 4" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
          </svg>
        </button>
        <div v-else class="w-20" />
      </div>
    </footer>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { RouterLink } from 'vue-router'
import { useStepNav } from '../composables/useStepNav.js'

defineProps<{
  title: string
  subtitle?: string
}>()

const { currentStep, totalSteps, canProceed, next, prev, goTo } = useStepNav()

const stepTitles = [
  'Desktop',
  'Packages',
  'App Bundles',
  'Kernel',
  'Locale',
  'Boot',
  'Review',
  'Build',
]

const stepTitle = computed(() => stepTitles[currentStep.value - 1] ?? '')
</script>
