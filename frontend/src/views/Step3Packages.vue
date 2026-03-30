<template>
  <WizardShell
    title="Choose Packages"
    subtitle="Search and select packages to pre-install on your distro. You can install more after booting."
  >
    <!-- Search bar -->
    <div class="relative mb-4">
      <svg class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-500" viewBox="0 0 16 16" fill="none">
        <circle cx="7" cy="7" r="4.5" stroke="currentColor" stroke-width="1.5" />
        <path d="M10.5 10.5L14 14" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" />
      </svg>
      <input
        v-model="queryInput"
        type="text"
        placeholder="Search packages..."
        class="w-full rounded-lg border border-slate-700 bg-slate-900 pl-10 pr-4 py-2.5 text-sm text-slate-100 placeholder-slate-500 focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500 transition-colors"
        @input="onInput"
      />
      <button
        v-if="queryInput"
        type="button"
        class="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 hover:text-slate-300"
        @click="clearSearch()"
      >
        ✕
      </button>
    </div>

    <!-- Selected count -->
    <div class="flex items-center justify-between mb-3">
      <span class="text-xs text-slate-400">
        {{ selectedPackages.length }} package{{ selectedPackages.length !== 1 ? 's' : '' }} selected
      </span>
      <button
        v-if="selectedPackages.length > 0"
        type="button"
        class="text-xs text-red-400 hover:text-red-300 transition-colors"
        @click="configStore.setField('packages', [])"
      >
        Clear all
      </button>
    </div>

    <!-- Loading -->
    <div v-if="isLoading" class="flex justify-center py-12">
      <div class="h-8 w-8 rounded-full border-2 border-brand-500 border-t-transparent animate-spin" />
    </div>

    <!-- Error -->
    <div v-else-if="searchError" class="rounded-lg border border-red-800 bg-red-950/30 p-4 text-sm text-red-400">
      {{ searchError }}
    </div>

    <!-- Results -->
    <div v-else class="space-y-1.5 max-h-[480px] overflow-y-auto pr-1">
      <div
        v-for="pkg in results"
        :key="pkg.id"
        :class="[
          'flex items-center gap-3 rounded-lg border px-4 py-3 cursor-pointer transition-all',
          isSelected(pkg.id)
            ? 'border-brand-600 bg-brand-950/50'
            : 'border-slate-800 bg-slate-900/60 hover:border-slate-700 hover:bg-slate-800/60',
        ]"
        @click="configStore.togglePackage(pkg.id)"
      >
        <div
          :class="[
            'flex h-5 w-5 shrink-0 items-center justify-center rounded border transition-colors',
            isSelected(pkg.id)
              ? 'border-brand-500 bg-brand-500'
              : 'border-slate-600 bg-transparent',
          ]"
        >
          <svg v-if="isSelected(pkg.id)" class="h-3 w-3 text-white" viewBox="0 0 12 12" fill="none">
            <path d="M2 6l3 3 5-5" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
          </svg>
        </div>

        <div class="flex-1 min-w-0">
          <div class="flex items-center gap-2">
            <span :class="['text-sm font-semibold font-mono', isSelected(pkg.id) ? 'text-brand-300' : 'text-slate-200']">
              {{ pkg.name }}
            </span>
            <span class="hidden sm:inline-block rounded px-1.5 py-0.5 text-xs bg-slate-800 text-slate-400">
              {{ pkg.category }}
            </span>
          </div>
          <p class="text-xs text-slate-400 mt-0.5 truncate">{{ pkg.description }}</p>
        </div>

        <span class="text-xs text-slate-500 shrink-0">{{ pkg.size }} MB</span>
      </div>

      <div v-if="results.length === 0 && !isLoading" class="py-8 text-center text-sm text-slate-500">
        No packages found for "{{ queryInput }}"
      </div>
    </div>
  </WizardShell>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import WizardShell from '../components/WizardShell.vue'
import { useConfigStore } from '../stores/config.js'
import { usePackageSearch } from '../composables/usePackageSearch.js'

const configStore = useConfigStore()
const queryInput = ref('')

const { results, isLoading, searchError, search, clearSearch } = usePackageSearch()

const selectedPackages = computed(() => configStore.config.packages ?? [])

function isSelected(id: string): boolean {
  return selectedPackages.value.includes(id)
}

function onInput(): void {
  search(queryInput.value)
}
</script>
