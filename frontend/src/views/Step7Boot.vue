<template>
  <WizardShell
    title="Boot Configuration"
    subtitle="Customise the GRUB bootloader appearance and behavior."
  >
    <div class="space-y-6 max-w-2xl">
      <!-- GRUB Theme -->
      <div>
        <label class="block text-sm font-medium text-slate-300 mb-2">
          GRUB Theme
        </label>
        <div class="grid grid-cols-2 sm:grid-cols-3 gap-3">
          <button
            v-for="theme in grubThemes"
            :key="theme.id"
            type="button"
            :class="[
              'flex flex-col items-center gap-2 rounded-xl border-2 p-4 transition-all focus:outline-none focus-visible:ring-2 focus-visible:ring-brand-400',
              configStore.config.boot?.grubTheme === theme.id
                ? 'border-brand-500 bg-brand-950/50'
                : 'border-slate-700 bg-slate-900/60 hover:border-slate-600',
            ]"
            @click="configStore.setBootField('grubTheme', theme.id)"
          >
            <span class="text-2xl">{{ theme.preview }}</span>
            <span
              :class="[
                'text-xs font-medium',
                configStore.config.boot?.grubTheme === theme.id ? 'text-brand-300' : 'text-slate-300',
              ]"
            >
              {{ theme.name }}
            </span>
          </button>
        </div>
      </div>

      <!-- Splash screen toggle -->
      <div class="flex items-center justify-between rounded-xl border border-slate-700 bg-slate-900/60 p-4">
        <div>
          <p class="text-sm font-medium text-slate-200">Splash Screen</p>
          <p class="text-xs text-slate-400 mt-0.5">Show Plymouth splash screen during boot</p>
        </div>
        <button
          type="button"
          role="switch"
          :aria-checked="configStore.config.boot?.splashScreen"
          :class="[
            'relative inline-flex h-6 w-11 items-center rounded-full transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-brand-400',
            configStore.config.boot?.splashScreen ? 'bg-brand-500' : 'bg-slate-700',
          ]"
          @click="configStore.setBootField('splashScreen', !configStore.config.boot?.splashScreen)"
        >
          <span
            :class="[
              'inline-block h-4 w-4 transform rounded-full bg-white shadow transition-transform',
              configStore.config.boot?.splashScreen ? 'translate-x-6' : 'translate-x-1',
            ]"
          />
        </button>
      </div>

      <!-- Boot timeout -->
      <div>
        <div class="flex items-center justify-between mb-2">
          <label class="text-sm font-medium text-slate-300">Boot Timeout</label>
          <span class="text-sm font-mono text-brand-300">
            {{ configStore.config.boot?.timeout }}s
          </span>
        </div>
        <input
          type="range"
          min="0"
          max="30"
          step="1"
          :value="configStore.config.boot?.timeout"
          class="w-full h-2 rounded-full appearance-none cursor-pointer accent-brand-500 bg-slate-800"
          @input="onTimeout($event)"
        />
        <div class="flex justify-between text-xs text-slate-500 mt-1">
          <span>0s (instant)</span>
          <span>15s</span>
          <span>30s</span>
        </div>
        <p v-if="configStore.config.boot?.timeout === 0" class="mt-2 text-xs text-amber-400">
          Warning: 0s timeout will boot immediately without showing the GRUB menu.
        </p>
      </div>

      <!-- Preview -->
      <div class="rounded-xl border border-slate-800 bg-slate-950 p-4 font-mono text-xs">
        <p class="text-slate-500 mb-2"># /etc/default/grub</p>
        <p class="text-emerald-400">GRUB_TIMEOUT=<span class="text-amber-300">{{ configStore.config.boot?.timeout }}</span></p>
        <p class="text-emerald-400">GRUB_THEME=<span class="text-amber-300">"/boot/grub/themes/{{ configStore.config.boot?.grubTheme }}/theme.txt"</span></p>
        <p v-if="!configStore.config.boot?.splashScreen" class="text-emerald-400">
          GRUB_CMDLINE_LINUX_DEFAULT=<span class="text-amber-300">"quiet nosplash"</span>
        </p>
        <p v-else class="text-emerald-400">
          GRUB_CMDLINE_LINUX_DEFAULT=<span class="text-amber-300">"quiet splash"</span>
        </p>
      </div>
    </div>
  </WizardShell>
</template>

<script setup lang="ts">
import WizardShell from '../components/WizardShell.vue'
import { useConfigStore } from '../stores/config.js'

const configStore = useConfigStore()

function onTimeout(event: Event): void {
  configStore.setBootField('timeout', parseInt((event.target as HTMLInputElement).value, 10))
}

const grubThemes = [
  { id: 'default', name: 'Default', preview: '⬛' },
  { id: 'vimix', name: 'Vimix', preview: '🌑' },
  { id: 'tela', name: 'Tela', preview: '🔵' },
  { id: 'whitesur', name: 'WhiteSur', preview: '⬜' },
  { id: 'minegrub', name: 'MineGRUB', preview: '🪨' },
  { id: 'makeyourpoison', name: 'MakeYourPoison', preview: '🔮' },
]
</script>
