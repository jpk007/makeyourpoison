<template>
  <WizardShell
    title="Locale & Language"
    subtitle="Set the default timezone, system language, and keyboard layout for your distro."
  >
    <div class="space-y-6 max-w-2xl">
      <!-- Timezone -->
      <div>
        <label class="block text-sm font-medium text-slate-300 mb-2">
          Timezone
        </label>
        <select
          :value="configStore.config.locale?.timezone"
          class="w-full rounded-lg border border-slate-700 bg-slate-900 px-3 py-2.5 text-sm text-slate-100 focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500 transition-colors"
          @change="onTimezone($event)"
        >
          <optgroup v-for="group in timezoneGroups" :key="group.label" :label="group.label">
            <option v-for="tz in group.zones" :key="tz.value" :value="tz.value">
              {{ tz.label }}
            </option>
          </optgroup>
        </select>
      </div>

      <!-- Language -->
      <div>
        <label class="block text-sm font-medium text-slate-300 mb-2">
          System Language
        </label>
        <select
          :value="configStore.config.locale?.language"
          class="w-full rounded-lg border border-slate-700 bg-slate-900 px-3 py-2.5 text-sm text-slate-100 focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500 transition-colors"
          @change="onLanguage($event)"
        >
          <option v-for="lang in languages" :key="lang.value" :value="lang.value">
            {{ lang.label }}
          </option>
        </select>
      </div>

      <!-- Keyboard -->
      <div>
        <label class="block text-sm font-medium text-slate-300 mb-2">
          Keyboard Layout
        </label>
        <select
          :value="configStore.config.locale?.keyboard"
          class="w-full rounded-lg border border-slate-700 bg-slate-900 px-3 py-2.5 text-sm text-slate-100 focus:border-brand-500 focus:outline-none focus:ring-1 focus:ring-brand-500 transition-colors"
          @change="onKeyboard($event)"
        >
          <option v-for="kb in keyboards" :key="kb.value" :value="kb.value">
            {{ kb.label }}
          </option>
        </select>
      </div>

      <!-- Preview -->
      <div class="rounded-xl border border-slate-800 bg-slate-900/40 p-4">
        <h3 class="text-xs font-semibold text-slate-400 mb-3 uppercase tracking-wide">Preview</h3>
        <div class="space-y-2 font-mono text-sm">
          <div class="flex gap-2">
            <span class="text-slate-500 w-28">LANG=</span>
            <span class="text-brand-300">{{ configStore.config.locale?.language }}</span>
          </div>
          <div class="flex gap-2">
            <span class="text-slate-500 w-28">TZ=</span>
            <span class="text-brand-300">{{ configStore.config.locale?.timezone }}</span>
          </div>
          <div class="flex gap-2">
            <span class="text-slate-500 w-28">KEYMAP=</span>
            <span class="text-brand-300">{{ configStore.config.locale?.keyboard }}</span>
          </div>
        </div>
      </div>
    </div>
  </WizardShell>
</template>

<script setup lang="ts">
import WizardShell from '../components/WizardShell.vue'
import { useConfigStore } from '../stores/config.js'

const configStore = useConfigStore()

function onTimezone(event: Event): void {
  configStore.setLocaleField('timezone', (event.target as HTMLSelectElement).value)
}
function onLanguage(event: Event): void {
  configStore.setLocaleField('language', (event.target as HTMLSelectElement).value)
}
function onKeyboard(event: Event): void {
  configStore.setLocaleField('keyboard', (event.target as HTMLSelectElement).value)
}

const timezoneGroups = [
  {
    label: 'Universal',
    zones: [{ value: 'UTC', label: 'UTC — Coordinated Universal Time' }],
  },
  {
    label: 'Americas',
    zones: [
      { value: 'America/New_York', label: 'America/New_York (EST/EDT)' },
      { value: 'America/Chicago', label: 'America/Chicago (CST/CDT)' },
      { value: 'America/Denver', label: 'America/Denver (MST/MDT)' },
      { value: 'America/Los_Angeles', label: 'America/Los_Angeles (PST/PDT)' },
      { value: 'America/Toronto', label: 'America/Toronto' },
      { value: 'America/Vancouver', label: 'America/Vancouver' },
      { value: 'America/Sao_Paulo', label: 'America/Sao_Paulo' },
      { value: 'America/Mexico_City', label: 'America/Mexico_City' },
    ],
  },
  {
    label: 'Europe',
    zones: [
      { value: 'Europe/London', label: 'Europe/London (GMT/BST)' },
      { value: 'Europe/Paris', label: 'Europe/Paris (CET/CEST)' },
      { value: 'Europe/Berlin', label: 'Europe/Berlin' },
      { value: 'Europe/Rome', label: 'Europe/Rome' },
      { value: 'Europe/Madrid', label: 'Europe/Madrid' },
      { value: 'Europe/Amsterdam', label: 'Europe/Amsterdam' },
      { value: 'Europe/Warsaw', label: 'Europe/Warsaw' },
      { value: 'Europe/Stockholm', label: 'Europe/Stockholm' },
      { value: 'Europe/Kiev', label: 'Europe/Kiev' },
      { value: 'Europe/Moscow', label: 'Europe/Moscow' },
    ],
  },
  {
    label: 'Asia / Pacific',
    zones: [
      { value: 'Asia/Tokyo', label: 'Asia/Tokyo (JST)' },
      { value: 'Asia/Shanghai', label: 'Asia/Shanghai (CST)' },
      { value: 'Asia/Kolkata', label: 'Asia/Kolkata (IST)' },
      { value: 'Asia/Dubai', label: 'Asia/Dubai (GST)' },
      { value: 'Asia/Singapore', label: 'Asia/Singapore (SGT)' },
      { value: 'Asia/Seoul', label: 'Asia/Seoul (KST)' },
      { value: 'Australia/Sydney', label: 'Australia/Sydney (AEST)' },
      { value: 'Australia/Perth', label: 'Australia/Perth (AWST)' },
      { value: 'Pacific/Auckland', label: 'Pacific/Auckland (NZST)' },
    ],
  },
  {
    label: 'Africa',
    zones: [
      { value: 'Africa/Cairo', label: 'Africa/Cairo (EET)' },
      { value: 'Africa/Johannesburg', label: 'Africa/Johannesburg (SAST)' },
      { value: 'Africa/Lagos', label: 'Africa/Lagos (WAT)' },
    ],
  },
]

const languages = [
  { value: 'en_US.UTF-8', label: 'English (United States)' },
  { value: 'en_GB.UTF-8', label: 'English (United Kingdom)' },
  { value: 'en_CA.UTF-8', label: 'English (Canada)' },
  { value: 'en_AU.UTF-8', label: 'English (Australia)' },
  { value: 'de_DE.UTF-8', label: 'Deutsch (Deutschland)' },
  { value: 'fr_FR.UTF-8', label: 'Français (France)' },
  { value: 'es_ES.UTF-8', label: 'Español (España)' },
  { value: 'es_MX.UTF-8', label: 'Español (México)' },
  { value: 'pt_BR.UTF-8', label: 'Português (Brasil)' },
  { value: 'pt_PT.UTF-8', label: 'Português (Portugal)' },
  { value: 'it_IT.UTF-8', label: 'Italiano (Italia)' },
  { value: 'nl_NL.UTF-8', label: 'Nederlands (Nederland)' },
  { value: 'pl_PL.UTF-8', label: 'Polski (Polska)' },
  { value: 'ru_RU.UTF-8', label: 'Русский (Россия)' },
  { value: 'ja_JP.UTF-8', label: '日本語 (日本)' },
  { value: 'zh_CN.UTF-8', label: '中文 (简体)' },
  { value: 'zh_TW.UTF-8', label: '中文 (繁體)' },
  { value: 'ko_KR.UTF-8', label: '한국어 (대한민국)' },
  { value: 'ar_SA.UTF-8', label: 'العربية (المملكة العربية السعودية)' },
]

const keyboards = [
  { value: 'us', label: 'US (English QWERTY)' },
  { value: 'gb', label: 'GB (English UK)' },
  { value: 'de', label: 'DE (German QWERTZ)' },
  { value: 'fr', label: 'FR (French AZERTY)' },
  { value: 'es', label: 'ES (Spanish)' },
  { value: 'it', label: 'IT (Italian)' },
  { value: 'pt', label: 'PT (Portuguese)' },
  { value: 'br', label: 'BR (Brazilian Portuguese)' },
  { value: 'nl', label: 'NL (Dutch)' },
  { value: 'pl', label: 'PL (Polish)' },
  { value: 'ru', label: 'RU (Russian)' },
  { value: 'jp', label: 'JP (Japanese)' },
  { value: 'dvorak', label: 'Dvorak' },
  { value: 'colemak', label: 'Colemak' },
]
</script>
