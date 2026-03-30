<template>
  <WizardShell
    title="Choose Your Kernel"
    subtitle="The kernel variant determines hardware support, latency characteristics, and security posture."
  >
    <div class="space-y-3">
      <label
        v-for="kernel in kernels"
        :key="kernel.id"
        :class="[
          'flex items-start gap-4 rounded-xl border-2 p-5 cursor-pointer transition-all',
          configStore.config.kernel === kernel.id
            ? 'border-brand-500 bg-brand-950/50'
            : 'border-slate-700 bg-slate-900/60 hover:border-slate-600',
        ]"
      >
        <input
          type="radio"
          name="kernel"
          :value="kernel.id"
          :checked="configStore.config.kernel === kernel.id"
          class="sr-only"
          @change="configStore.setField('kernel', kernel.id)"
        />

        <!-- Radio indicator -->
        <div class="mt-0.5 flex h-5 w-5 shrink-0 items-center justify-center rounded-full border-2 transition-colors"
          :class="configStore.config.kernel === kernel.id ? 'border-brand-500 bg-brand-500' : 'border-slate-600'"
        >
          <div v-if="configStore.config.kernel === kernel.id" class="h-2 w-2 rounded-full bg-white" />
        </div>

        <div class="flex-1">
          <div class="flex items-center gap-2 flex-wrap">
            <span :class="['font-semibold', configStore.config.kernel === kernel.id ? 'text-brand-300' : 'text-slate-200']">
              {{ kernel.name }}
            </span>
            <span class="font-mono text-xs px-1.5 py-0.5 rounded bg-slate-800 text-slate-400">
              {{ kernel.variant }}
            </span>
            <span
              v-if="kernel.badge"
              :class="[
                'text-xs rounded-full px-2 py-0.5 font-medium',
                kernel.badgeVariant === 'green' ? 'bg-emerald-900/60 text-emerald-400' :
                kernel.badgeVariant === 'yellow' ? 'bg-amber-900/60 text-amber-400' :
                kernel.badgeVariant === 'red' ? 'bg-red-900/60 text-red-400' :
                'bg-slate-800 text-slate-400',
              ]"
            >
              {{ kernel.badge }}
            </span>
          </div>
          <p class="mt-1 text-sm text-slate-400">{{ kernel.description }}</p>

          <!-- Stats -->
          <div class="mt-3 flex flex-wrap gap-4">
            <div v-for="stat in kernel.stats" :key="stat.label" class="text-xs">
              <span class="text-slate-500">{{ stat.label }}:</span>
              <span class="ml-1 text-slate-300">{{ stat.value }}</span>
            </div>
          </div>
        </div>
      </label>
    </div>
  </WizardShell>
</template>

<script setup lang="ts">
import WizardShell from '../components/WizardShell.vue'
import { useConfigStore } from '../stores/config.js'
import type { Kernel } from '@distroforge/shared'

const configStore = useConfigStore()

const kernels: {
  id: Kernel
  name: string
  variant: string
  description: string
  badge?: string
  badgeVariant?: 'green' | 'yellow' | 'red' | 'default'
  stats: { label: string; value: string }[]
}[] = [
  {
    id: 'generic',
    name: 'Generic',
    variant: 'linux-generic',
    description: 'The standard kernel. Broad hardware support, conservative scheduling, suitable for most use cases.',
    badge: 'Recommended',
    badgeVariant: 'green',
    stats: [
      { label: 'Latency', value: 'Standard' },
      { label: 'Hardware', value: 'Universal' },
      { label: 'Stability', value: 'Excellent' },
    ],
  },
  {
    id: 'lowlatency',
    name: 'Low Latency',
    variant: 'linux-lowlatency',
    description: 'Optimised for minimal input lag. Ideal for audio production, desktop responsiveness, and gaming.',
    badge: 'Desktop',
    badgeVariant: 'default',
    stats: [
      { label: 'Latency', value: 'Very Low' },
      { label: 'Hardware', value: 'Universal' },
      { label: 'Stability', value: 'Good' },
    ],
  },
  {
    id: 'zen',
    name: 'Zen',
    variant: 'linux-zen',
    description: 'Community-maintained kernel with patches for desktop performance, gaming, and interactivity. Arch-native.',
    badge: 'Performance',
    badgeVariant: 'yellow',
    stats: [
      { label: 'Latency', value: 'Low' },
      { label: 'Hardware', value: 'Good' },
      { label: 'Stability', value: 'Good' },
    ],
  },
  {
    id: 'hardened',
    name: 'Hardened',
    variant: 'linux-hardened',
    description: 'Security-focused kernel with extra exploit mitigations, stricter defaults, and reduced attack surface.',
    badge: 'Security',
    badgeVariant: 'red',
    stats: [
      { label: 'Latency', value: 'Higher' },
      { label: 'Hardware', value: 'Limited' },
      { label: 'Stability', value: 'Excellent' },
    ],
  },
]
</script>
