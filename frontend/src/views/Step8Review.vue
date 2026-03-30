<template>
  <WizardShell
    title="Review Your Configuration"
    subtitle="Everything looks good? Hit Continue to start the build."
  >
    <div class="space-y-4">
      <!-- ISO file name -->
      <div class="rounded-xl border border-slate-700 bg-slate-900/60 p-4">
        <label class="block text-xs font-semibold text-slate-400 uppercase tracking-wide mb-2">
          ISO File Name
        </label>
        <div class="flex items-center gap-2">
          <input
            :value="config.isoName"
            type="text"
            placeholder="makeyourpoison"
            maxlength="64"
            class="flex-1 rounded-lg border border-slate-700 bg-slate-950 px-3 py-2 text-sm font-mono text-slate-100 placeholder-slate-600 focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500 transition-colors"
            @input="onIsoNameInput"
          />
          <span class="text-sm text-slate-500 font-mono shrink-0">.iso</span>
        </div>
        <p v-if="isoNameError" class="mt-1.5 text-xs text-red-400">{{ isoNameError }}</p>
        <p v-else class="mt-1.5 text-xs text-slate-500">Letters, numbers, hyphens and underscores only</p>
      </div>

      <!-- ISO size estimate -->
      <div class="rounded-xl border border-brand-700/50 bg-brand-950/30 p-5 flex items-center gap-4">
        <span class="text-3xl">💿</span>
        <div>
          <p class="text-sm text-slate-400">Estimated ISO Size</p>
          <p class="text-2xl font-bold text-brand-300">~{{ estimatedSize }} GB</p>
        </div>
        <div class="ml-auto text-right">
          <p class="text-xs text-slate-500">Build time</p>
          <p class="text-sm font-medium text-slate-300">~{{ estimatedBuildTime }} min</p>
        </div>
      </div>

      <!-- Config sections -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <!-- Desktop & System -->
        <div class="rounded-xl border border-slate-800 bg-slate-900/60 p-4">
          <h3 class="text-xs font-semibold text-slate-400 uppercase tracking-wide mb-3">System</h3>
          <dl class="space-y-2">
            <div class="flex justify-between items-center">
              <dt class="text-sm text-slate-400">Base</dt>
              <dd class="text-sm font-medium text-slate-200">
                <span class="px-2 py-0.5 rounded text-xs font-mono bg-slate-800 text-brand-300">scratch</span>
              </dd>
            </div>
            <div class="flex justify-between items-center">
              <dt class="text-sm text-slate-400">Desktop</dt>
              <dd class="text-sm font-medium">
                <span :class="['px-2 py-0.5 rounded text-xs font-mono', config.desktop ? 'bg-slate-800 text-brand-300' : 'text-red-400']">
                  {{ config.desktop ?? 'Not set' }}
                </span>
              </dd>
            </div>
            <div class="flex justify-between items-center">
              <dt class="text-sm text-slate-400">Kernel</dt>
              <dd class="text-sm font-medium">
                <span :class="['px-2 py-0.5 rounded text-xs font-mono', config.kernel ? 'bg-slate-800 text-brand-300' : 'text-red-400']">
                  {{ config.kernel ?? 'Not set' }}
                </span>
              </dd>
            </div>
          </dl>
        </div>

        <!-- Locale -->
        <div class="rounded-xl border border-slate-800 bg-slate-900/60 p-4">
          <h3 class="text-xs font-semibold text-slate-400 uppercase tracking-wide mb-3">Locale</h3>
          <dl class="space-y-2">
            <div class="flex justify-between items-center">
              <dt class="text-sm text-slate-400">Timezone</dt>
              <dd class="text-xs font-mono text-slate-300">{{ config.locale?.timezone }}</dd>
            </div>
            <div class="flex justify-between items-center">
              <dt class="text-sm text-slate-400">Language</dt>
              <dd class="text-xs font-mono text-slate-300">{{ config.locale?.language }}</dd>
            </div>
            <div class="flex justify-between items-center">
              <dt class="text-sm text-slate-400">Keyboard</dt>
              <dd class="text-xs font-mono text-slate-300">{{ config.locale?.keyboard }}</dd>
            </div>
          </dl>
        </div>

        <!-- Boot -->
        <div class="rounded-xl border border-slate-800 bg-slate-900/60 p-4">
          <h3 class="text-xs font-semibold text-slate-400 uppercase tracking-wide mb-3">Boot</h3>
          <dl class="space-y-2">
            <div class="flex justify-between items-center">
              <dt class="text-sm text-slate-400">GRUB Theme</dt>
              <dd class="text-xs font-mono text-slate-300">{{ config.boot?.grubTheme }}</dd>
            </div>
            <div class="flex justify-between items-center">
              <dt class="text-sm text-slate-400">Splash Screen</dt>
              <dd>
                <span :class="['text-xs rounded-full px-2 py-0.5 font-medium', config.boot?.splashScreen ? 'bg-emerald-900/60 text-emerald-400' : 'bg-slate-800 text-slate-400']">
                  {{ config.boot?.splashScreen ? 'Enabled' : 'Disabled' }}
                </span>
              </dd>
            </div>
            <div class="flex justify-between items-center">
              <dt class="text-sm text-slate-400">Timeout</dt>
              <dd class="text-xs font-mono text-slate-300">{{ config.boot?.timeout }}s</dd>
            </div>
          </dl>
        </div>

        <!-- App Bundles -->
        <div class="rounded-xl border border-slate-800 bg-slate-900/60 p-4">
          <h3 class="text-xs font-semibold text-slate-400 uppercase tracking-wide mb-3">App Bundles</h3>
          <div v-if="config.appBundles && config.appBundles.length > 0" class="flex flex-wrap gap-2">
            <span
              v-for="bundle in config.appBundles"
              :key="bundle"
              class="rounded-full px-2.5 py-1 text-xs font-medium bg-brand-900/60 text-brand-300 capitalize"
            >
              {{ bundle }}
            </span>
          </div>
          <p v-else class="text-sm text-slate-500">None selected</p>
        </div>
      </div>

      <!-- Packages -->
      <div class="rounded-xl border border-slate-800 bg-slate-900/60 p-4">
        <h3 class="text-xs font-semibold text-slate-400 uppercase tracking-wide mb-3">
          Selected Packages
          <span class="ml-2 text-brand-400">({{ config.packages?.length ?? 0 }})</span>
        </h3>
        <div v-if="config.packages && config.packages.length > 0" class="flex flex-wrap gap-1.5">
          <span
            v-for="pkg in config.packages"
            :key="pkg"
            class="rounded px-2 py-0.5 text-xs font-mono bg-slate-800 text-slate-300"
          >
            {{ pkg }}
          </span>
        </div>
        <p v-else class="text-sm text-slate-500">No extra packages selected</p>
      </div>

      <!-- Validation errors -->
      <div v-if="validationErrors.length > 0" class="rounded-xl border border-red-800 bg-red-950/30 p-4">
        <p class="text-sm font-semibold text-red-400 mb-2">Please fix the following before continuing:</p>
        <ul class="list-disc list-inside space-y-1">
          <li v-for="err in validationErrors" :key="err" class="text-sm text-red-300">{{ err }}</li>
        </ul>
      </div>
    </div>
  </WizardShell>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import WizardShell from '../components/WizardShell.vue'
import { useConfigStore } from '../stores/config.js'

const configStore = useConfigStore()
const config = computed(() => configStore.config)

const ISO_NAME_RE = /^[a-zA-Z0-9_-]+$/
const isoNameError = ref<string | null>(null)

function onIsoNameInput(e: Event): void {
  const value = (e.target as HTMLInputElement).value
  if (!value) {
    isoNameError.value = 'Name cannot be empty'
  } else if (!ISO_NAME_RE.test(value)) {
    isoNameError.value = 'Only letters, numbers, hyphens and underscores'
  } else {
    isoNameError.value = null
    configStore.setField('isoName', value)
  }
}

const estimatedSize = computed(() => {
  let base = 1.5
  const desktop = config.value.desktop
  if (desktop === 'gnome') base += 0.8
  else if (desktop === 'kde') base += 0.7
  else if (desktop === 'xfce') base += 0.4
  else if (desktop === 'hyprland') base += 0.3

  const bundles = config.value.appBundles ?? []
  if (bundles.includes('dev')) base += 2.1
  if (bundles.includes('office')) base += 0.8
  if (bundles.includes('gaming')) base += 1.5
  if (bundles.includes('minimal')) base += 0.3

  const pkgCount = config.value.packages?.length ?? 0
  base += pkgCount * 0.03

  return base.toFixed(1)
})

const estimatedBuildTime = computed(() => {
  const size = parseFloat(estimatedSize.value)
  return Math.ceil(size * 3)
})

const validationErrors = computed(() => {
  const errors: string[] = []
  if (!config.value.desktop) errors.push('Desktop environment is required (Step 1)')
  if (!config.value.kernel) errors.push('Kernel is required (Step 4)')
  if (!config.value.locale?.timezone) errors.push('Timezone is required (Step 5)')
  if (!config.value.locale?.language) errors.push('Language is required (Step 5)')
  if (!config.value.locale?.keyboard) errors.push('Keyboard layout is required (Step 5)')
  return errors
})
</script>
