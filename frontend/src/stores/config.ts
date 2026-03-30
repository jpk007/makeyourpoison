import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { DistroConfig } from '@distroforge/shared'
import { saveConfig } from '../api/client.js'

type PartialDistroConfig = Partial<DistroConfig>

export const useConfigStore = defineStore('config', () => {
  const config = ref<PartialDistroConfig>({
    base: 'scratch',
    isoName: 'makeyourpoison',
    desktop: undefined,
    kernel: undefined,
    packages: [],
    appBundles: [],
    locale: {
      timezone: 'UTC',
      language: 'en_US.UTF-8',
      keyboard: 'us',
    },
    boot: {
      grubTheme: 'default',
      splashScreen: true,
      timeout: 5,
    },
  })

  const savedConfigId = ref<string | null>(null)
  const isSaving = ref(false)
  const saveError = ref<string | null>(null)

  function setField<K extends keyof DistroConfig>(key: K, value: DistroConfig[K]): void {
    ;(config.value as DistroConfig)[key] = value
  }

  function setLocaleField(
    key: keyof DistroConfig['locale'],
    value: string
  ): void {
    if (!config.value.locale) {
      config.value.locale = { timezone: 'UTC', language: 'en_US.UTF-8', keyboard: 'us' }
    }
    config.value.locale[key] = value
  }

  function setBootField(
    key: keyof DistroConfig['boot'],
    value: string | boolean | number
  ): void {
    if (!config.value.boot) {
      config.value.boot = { grubTheme: 'default', splashScreen: true, timeout: 5 }
    }
    // Type-safe assignment using conditional logic
    if (key === 'splashScreen' && typeof value === 'boolean') {
      config.value.boot.splashScreen = value
    } else if (key === 'timeout' && typeof value === 'number') {
      config.value.boot.timeout = value
    } else if (key === 'grubTheme' && typeof value === 'string') {
      config.value.boot.grubTheme = value
    }
  }

  function togglePackage(pkg: string): void {
    const pkgs = config.value.packages ?? []
    const idx = pkgs.indexOf(pkg)
    if (idx >= 0) {
      pkgs.splice(idx, 1)
    } else {
      pkgs.push(pkg)
    }
    config.value.packages = [...pkgs]
  }

  function toggleBundle(bundle: string): void {
    const bundles = config.value.appBundles ?? []
    const idx = bundles.indexOf(bundle)
    if (idx >= 0) {
      bundles.splice(idx, 1)
    } else {
      bundles.push(bundle)
    }
    config.value.appBundles = [...bundles]
  }

  function reset(): void {
    config.value = {
      base: 'scratch',
      isoName: 'makeyourpoison',
      desktop: undefined,
      kernel: undefined,
      packages: [],
      appBundles: [],
      locale: {
        timezone: 'UTC',
        language: 'en_US.UTF-8',
        keyboard: 'us',
      },
      boot: {
        grubTheme: 'default',
        splashScreen: true,
        timeout: 5,
      },
    }
    savedConfigId.value = null
    saveError.value = null
  }

  async function persistConfig(): Promise<string | null> {
    // Validate required fields are set
    if (!config.value.desktop || !config.value.kernel) {
      saveError.value = 'Please complete all required steps first.'
      return null
    }

    isSaving.value = true
    saveError.value = null

    try {
      const fullConfig = config.value as DistroConfig
      const response = await saveConfig(fullConfig)
      savedConfigId.value = response.configId
      return response.configId
    } catch (err) {
      saveError.value = err instanceof Error ? err.message : 'Failed to save configuration.'
      return null
    } finally {
      isSaving.value = false
    }
  }

  return {
    config,
    savedConfigId,
    isSaving,
    saveError,
    setField,
    setLocaleField,
    setBootField,
    togglePackage,
    toggleBundle,
    reset,
    persistConfig,
  }
})
