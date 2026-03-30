import { ref } from 'vue'
import type { Package } from '@distroforge/shared'
import { searchPackages } from '../api/client.js'

export function usePackageSearch() {
  const query = ref('')
  const results = ref<Package[]>([])
  const isLoading = ref(false)
  const searchError = ref<string | null>(null)

  let debounceTimer: ReturnType<typeof setTimeout> | null = null

  async function doSearch(q: string): Promise<void> {
    isLoading.value = true
    searchError.value = null
    try {
      const data = await searchPackages(q)
      results.value = data.packages
    } catch (err) {
      searchError.value = err instanceof Error ? err.message : 'Search failed.'
      results.value = []
    } finally {
      isLoading.value = false
    }
  }

  function search(q: string): void {
    query.value = q
    if (debounceTimer) clearTimeout(debounceTimer)
    debounceTimer = setTimeout(() => {
      doSearch(q)
    }, 300)
  }

  function clearSearch(): void {
    query.value = ''
    results.value = []
    if (debounceTimer) clearTimeout(debounceTimer)
  }

  // Initial load
  doSearch('')

  return {
    query,
    results,
    isLoading,
    searchError,
    search,
    clearSearch,
  }
}
