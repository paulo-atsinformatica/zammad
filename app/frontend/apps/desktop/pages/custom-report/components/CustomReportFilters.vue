<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->
<!-- Customização ATS: relatório personalizado. -->

<script setup lang="ts">
import { reactive } from 'vue'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

import type { AvailableFilter, RuntimeFilters } from '../types.ts'

interface Props {
  // Apenas os atributos que o relatório habilitou. Quem monta essa lista é o
  // backend, então a tela não decide o que pode ser filtrado.
  available: AvailableFilter[]
  modelValue: RuntimeFilters
}

const props = defineProps<Props>()

const emit = defineEmits<{
  apply: [RuntimeFilters]
}>()

// Estado local para o usuário digitar sem refazer a consulta a cada tecla; a
// consulta só roda ao aplicar.
const draft = reactive<Record<string, string>>(
  Object.fromEntries(props.available.map(({ name }) => [name, props.modelValue[name]?.value ?? ''])),
)

const apply = () => {
  const filters: RuntimeFilters = {}

  Object.entries(draft).forEach(([name, value]) => {
    if (!value) return
    // 'contains' é mais útil que igualdade exata para filtro digitado à mão.
    filters[name] = { operator: 'contains', value }
  })

  emit('apply', filters)
}

const clear = () => {
  Object.keys(draft).forEach((key) => {
    draft[key] = ''
  })

  emit('apply', {})
}
</script>

<template>
  <div class="flex flex-col gap-3 rounded-lg bg-blue-200 p-4 dark:bg-gray-700">
    <div class="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
      <label v-for="filter in available" :key="filter.name" class="flex flex-col gap-1">
        <span class="text-sm text-stone-200 dark:text-neutral-500">{{ filter.display }}</span>
        <input
          v-model="draft[filter.name]"
          type="text"
          class="rounded-lg bg-white px-2 py-1 text-sm text-black dark:bg-gray-500 dark:text-white"
          @keyup.enter="apply"
        />
      </label>
    </div>

    <div class="flex gap-2">
      <CommonButton size="medium" variant="primary" @click="apply">
        {{ $t('Apply') }}
      </CommonButton>
      <CommonButton size="medium" @click="clear">
        {{ $t('Clear') }}
      </CommonButton>
    </div>
  </div>
</template>
