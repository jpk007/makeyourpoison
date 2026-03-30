<template>
  <button
    type="button"
    :class="[
      'group relative flex flex-col items-center gap-3 rounded-xl border-2 p-5 text-center transition-all duration-200 cursor-pointer w-full',
      'focus:outline-none focus-visible:ring-2 focus-visible:ring-brand-400 focus-visible:ring-offset-2 focus-visible:ring-offset-slate-950',
      selected
        ? 'border-brand-500 bg-brand-950/60 shadow-lg shadow-brand-900/40'
        : 'border-slate-700 bg-slate-900/60 hover:border-slate-500 hover:bg-slate-800/60',
    ]"
    @click="$emit('select')"
  >
    <!-- Selection indicator -->
    <span
      v-if="selected"
      class="absolute top-3 right-3 flex h-5 w-5 items-center justify-center rounded-full bg-brand-500"
    >
      <svg class="h-3 w-3 text-white" viewBox="0 0 12 12" fill="none">
        <path d="M2 6l3 3 5-5" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
      </svg>
    </span>

    <!-- Icon slot -->
    <span class="text-3xl" v-if="icon">{{ icon }}</span>
    <slot name="icon" />

    <!-- Label -->
    <span
      :class="[
        'text-sm font-semibold transition-colors',
        selected ? 'text-brand-300' : 'text-slate-200 group-hover:text-white',
      ]"
    >
      {{ label }}
    </span>

    <!-- Description -->
    <span v-if="description" class="text-xs text-slate-400 leading-snug">
      {{ description }}
    </span>

    <!-- Badge -->
    <span
      v-if="badge"
      :class="[
        'rounded-full px-2 py-0.5 text-xs font-medium',
        badgeVariant === 'green' ? 'bg-emerald-900/60 text-emerald-400' :
        badgeVariant === 'yellow' ? 'bg-amber-900/60 text-amber-400' :
        'bg-slate-800 text-slate-400',
      ]"
    >
      {{ badge }}
    </span>
  </button>
</template>

<script setup lang="ts">
defineProps<{
  label: string
  selected?: boolean
  icon?: string
  description?: string
  badge?: string
  badgeVariant?: 'green' | 'yellow' | 'default'
}>()

defineEmits<{
  select: []
}>()
</script>
