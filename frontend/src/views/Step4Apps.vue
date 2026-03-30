<template>
  <WizardShell
    title="Pre-installed App Bundles"
    subtitle="App bundles install curated sets of software for common use cases. Select all that apply."
  >
    <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
      <div
        v-for="bundle in bundles"
        :key="bundle.id"
        :class="[
          'relative rounded-xl border-2 p-5 cursor-pointer transition-all',
          isSelected(bundle.id)
            ? 'border-brand-500 bg-brand-950/50'
            : 'border-slate-700 bg-slate-900/60 hover:border-slate-600',
        ]"
        @click="configStore.toggleBundle(bundle.id)"
      >
        <!-- Checkbox indicator -->
        <div class="absolute top-4 right-4">
          <div
            :class="[
              'flex h-5 w-5 items-center justify-center rounded border-2 transition-colors',
              isSelected(bundle.id)
                ? 'border-brand-500 bg-brand-500'
                : 'border-slate-600 bg-transparent',
            ]"
          >
            <svg v-if="isSelected(bundle.id)" class="h-3 w-3 text-white" viewBox="0 0 12 12" fill="none">
              <path d="M2 6l3 3 5-5" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
            </svg>
          </div>
        </div>

        <div class="flex items-start gap-4 pr-8">
          <span class="text-3xl">{{ bundle.icon }}</span>
          <div class="flex-1">
            <h3 :class="['font-semibold mb-1', isSelected(bundle.id) ? 'text-brand-300' : 'text-slate-200']">
              {{ bundle.name }}
            </h3>
            <p class="text-xs text-slate-400 leading-relaxed mb-3">{{ bundle.description }}</p>
            <div class="flex flex-wrap gap-1.5">
              <span
                v-for="app in bundle.apps"
                :key="app"
                class="rounded px-2 py-0.5 text-xs font-mono bg-slate-800 text-slate-400"
              >
                {{ app }}
              </span>
            </div>
          </div>
        </div>

        <div class="mt-3 pt-3 border-t border-slate-700/60 flex items-center justify-between">
          <span class="text-xs text-slate-500">~{{ bundle.sizeGb }} GB added</span>
          <span
            :class="[
              'text-xs font-medium',
              isSelected(bundle.id) ? 'text-brand-400' : 'text-slate-500',
            ]"
          >
            {{ isSelected(bundle.id) ? 'Included' : 'Not included' }}
          </span>
        </div>
      </div>
    </div>

    <p class="mt-6 text-xs text-slate-500 text-center">
      Tip: You can skip all bundles and install only the packages from the previous step.
    </p>
  </WizardShell>
</template>

<script setup lang="ts">
import WizardShell from '../components/WizardShell.vue'
import { useConfigStore } from '../stores/config.js'

const configStore = useConfigStore()

const bundles = [
  {
    id: 'dev',
    name: 'Development',
    icon: '💻',
    description: 'Full development environment with editors, compilers, containers, and version control tools.',
    apps: ['VS Code', 'Git', 'Docker', 'Node.js', 'Python', 'GCC', 'Make', 'curl'],
    sizeGb: 2.1,
  },
  {
    id: 'office',
    name: 'Office',
    icon: '📄',
    description: 'Productivity suite for documents, spreadsheets, email, and communication.',
    apps: ['LibreOffice', 'Thunderbird', 'Evince', 'GNOME Calendar', 'Contacts'],
    sizeGb: 0.8,
  },
  {
    id: 'gaming',
    name: 'Gaming',
    icon: '🎮',
    description: 'Steam, Wine, Proton, and supporting libraries for gaming on Linux.',
    apps: ['Steam', 'Wine', 'Lutris', 'MangoHud', 'GameMode', 'Vulkan'],
    sizeGb: 1.5,
  },
  {
    id: 'minimal',
    name: 'Minimal',
    icon: '⚡',
    description: 'Just the bare essentials. A browser, terminal, and text editor. Nothing more.',
    apps: ['Firefox', 'Alacritty', 'Nano', 'htop'],
    sizeGb: 0.3,
  },
]

function isSelected(id: string): boolean {
  return (configStore.config.appBundles ?? []).includes(id)
}
</script>
