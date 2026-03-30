<template>
  <WizardShell
    title="Choose Your Base Distro"
    subtitle="The base distribution determines the package manager, release cycle, and default tooling."
  >
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
      <StepCard
        v-for="distro in distros"
        :key="distro.id"
        :label="distro.name"
        :icon="distro.icon"
        :description="distro.description"
        :badge="distro.badge"
        :badge-variant="distro.badgeVariant"
        :selected="configStore.config.base === distro.id"
        @select="select(distro.id)"
      />
    </div>

    <div class="mt-8 rounded-xl border border-slate-800 bg-slate-900/40 p-5">
      <h3 class="text-sm font-semibold text-slate-300 mb-3">Comparison</h3>
      <div class="overflow-x-auto">
        <table class="w-full text-xs text-slate-400">
          <thead>
            <tr class="border-b border-slate-800">
              <th class="pb-2 text-left font-medium text-slate-300">Distro</th>
              <th class="pb-2 text-left font-medium text-slate-300">Package Mgr</th>
              <th class="pb-2 text-left font-medium text-slate-300">Release</th>
              <th class="pb-2 text-left font-medium text-slate-300">Best For</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-800">
            <tr
              v-for="row in comparisonRows"
              :key="row.name"
              :class="configStore.config.base === row.id ? 'text-brand-300' : ''"
            >
              <td class="py-2 font-medium">{{ row.name }}</td>
              <td class="py-2 font-mono">{{ row.pkgMgr }}</td>
              <td class="py-2">{{ row.release }}</td>
              <td class="py-2">{{ row.bestFor }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </WizardShell>
</template>

<script setup lang="ts">
import WizardShell from '../components/WizardShell.vue'
import StepCard from '../components/StepCard.vue'
import { useConfigStore } from '../stores/config.js'
import type { BaseDistro } from '@distroforge/shared'

const configStore = useConfigStore()

const distros: {
  id: BaseDistro
  name: string
  icon: string
  description: string
  badge: string
  badgeVariant: 'green' | 'yellow' | 'default'
}[] = [
  {
    id: 'ubuntu',
    name: 'Ubuntu',
    icon: '🟠',
    description: 'Beginner-friendly, huge community, LTS support, APT packages.',
    badge: 'Recommended',
    badgeVariant: 'green',
  },
  {
    id: 'debian',
    name: 'Debian',
    icon: '🔴',
    description: 'Rock-solid stability, conservative updates, apt-based.',
    badge: 'Stable',
    badgeVariant: 'green',
  },
  {
    id: 'arch',
    name: 'Arch',
    icon: '🔵',
    description: 'Rolling release, cutting-edge packages, full control via pacman.',
    badge: 'Advanced',
    badgeVariant: 'yellow',
  },
  {
    id: 'fedora',
    name: 'Fedora',
    icon: '🎩',
    description: 'Latest GNOME, SELinux hardened, DNF packages, Red Hat upstream.',
    badge: 'Modern',
    badgeVariant: 'default',
  },
]

const comparisonRows = [
  { id: 'ubuntu', name: 'Ubuntu', pkgMgr: 'apt', release: 'LTS (2yr)', bestFor: 'Desktop, beginners' },
  { id: 'debian', name: 'Debian', pkgMgr: 'apt', release: 'Stable (~2yr)', bestFor: 'Servers, stability' },
  { id: 'arch', name: 'Arch', pkgMgr: 'pacman', release: 'Rolling', bestFor: 'Power users, DIY' },
  { id: 'fedora', name: 'Fedora', pkgMgr: 'dnf', release: '~6 months', bestFor: 'Developers, GNOME' },
]

function select(id: BaseDistro): void {
  configStore.setField('base', id)
  // Reset packages when base changes since catalogs differ
  configStore.setField('packages', [])
}
</script>
