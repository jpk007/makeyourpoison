import { computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useConfigStore } from '../stores/config.js'

const TOTAL_STEPS = 8

export function useStepNav() {
  const router = useRouter()
  const route = useRoute()
  const configStore = useConfigStore()

  const currentStep = computed(() => {
    const step = parseInt(route.meta.step as string, 10)
    return isNaN(step) ? 1 : step
  })

  const canProceed = computed((): boolean => {
    const cfg = configStore.config
    switch (currentStep.value) {
      case 1: // Desktop
        return !!cfg.desktop
      case 2: // Packages
        return true
      case 3: // App Bundles
        return true
      case 4: // Kernel
        return !!cfg.kernel
      case 5: // Locale
        return !!(cfg.locale?.timezone && cfg.locale?.language && cfg.locale?.keyboard)
      case 6: // Boot
        return cfg.boot?.timeout !== undefined
      case 7: // Review
        return true
      case 8: // Build
        return false
      default:
        return true
    }
  })

  function next(): void {
    if (currentStep.value < TOTAL_STEPS && canProceed.value) {
      router.push(`/step/${currentStep.value + 1}`)
    }
  }

  function prev(): void {
    if (currentStep.value > 1) {
      router.push(`/step/${currentStep.value - 1}`)
    }
  }

  function goTo(step: number): void {
    if (step >= 1 && step <= TOTAL_STEPS) {
      router.push(`/step/${step}`)
    }
  }

  return {
    currentStep,
    totalSteps: TOTAL_STEPS,
    canProceed,
    next,
    prev,
    goTo,
  }
}
