<template>
  <WizardShell
    title="Choose Your Desktop Environment"
    subtitle="Your desktop environment defines the visual shell, window manager, and default applications."
  >
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
      <StepCard
        v-for="de in desktops"
        :key="de.id"
        :label="de.name"
        :icon="de.icon"
        :description="de.description"
        :badge="de.badge"
        :badge-variant="de.badgeVariant"
        :selected="configStore.config.desktop === de.id"
        @select="configStore.setField('desktop', de.id)"
      />
    </div>

    <!-- Resource chart -->
    <div class="mt-8 rounded-xl border border-slate-800 bg-slate-900/40 p-5">
      <h3 class="text-sm font-semibold text-slate-300 mb-4">Resource Usage Estimate</h3>
      <div class="space-y-3">
        <div v-for="de in desktops.filter(d => d.id !== 'none')" :key="de.id" class="flex items-center gap-3">
          <span class="w-20 text-xs text-slate-400 shrink-0">{{ de.name }}</span>
          <div class="flex-1 h-2 bg-slate-800 rounded-full overflow-hidden">
            <div
              :class="['h-full rounded-full transition-all', configStore.config.desktop === de.id ? 'bg-brand-500' : 'bg-slate-600']"
              :style="{ width: de.ramPercent + '%' }"
            />
          </div>
          <span class="w-16 text-right text-xs text-slate-400">~{{ de.ramMb }} MB</span>
        </div>
      </div>
    </div>
  </WizardShell>
</template>

<script setup lang="ts">
import WizardShell from '../components/WizardShell.vue'
import StepCard from '../components/StepCard.vue'
import { useConfigStore } from '../stores/config.js'
import type { DesktopEnv } from '@distroforge/shared'

const configStore = useConfigStore()

const desktops: {
  id: DesktopEnv
  name: string
  icon: string
  description: string
  badge?: string
  badgeVariant?: 'green' | 'yellow' | 'default'
  ramMb: number
  ramPercent: number
}[] = [
  {
    id: 'gnome',
    name: 'GNOME',
    icon: '🟣',
    description: 'Modern, touch-friendly, Activities overview. Used by Ubuntu & Fedora defaults.',
    badge: 'Popular',
    badgeVariant: 'green',
    ramMb: 800,
    ramPercent: 80,
  },
  {
    id: 'kde',
    name: 'KDE Plasma',
    icon: '🔷',
    description: 'Highly customizable, Windows-like layout, feature-rich. Great for power users.',
    badge: 'Feature-rich',
    badgeVariant: 'default',
    ramMb: 600,
    ramPercent: 60,
  },
  {
    id: 'xfce',
    name: 'XFCE',
    icon: '🐭',
    description: 'Lightweight, fast, traditional desktop. Perfect for older hardware.',
    badge: 'Lightweight',
    badgeVariant: 'green',
    ramMb: 250,
    ramPercent: 25,
  },
  {
    id: 'hyprland',
    name: 'Hyprland',
    icon: '✨',
    description: 'Tiling Wayland compositor with fluid animations. Highly configurable via config files.',
    badge: 'Advanced',
    badgeVariant: 'yellow',
    ramMb: 150,
    ramPercent: 15,
  },
  {
    id: 'none',
    name: 'None (Server)',
    icon: '⬛',
    description: 'No graphical environment. SSH only. Smallest possible footprint.',
    ramMb: 50,
    ramPercent: 5,
  },
]
</script>
