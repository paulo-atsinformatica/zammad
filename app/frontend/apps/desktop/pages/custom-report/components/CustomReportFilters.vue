<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->
<!-- Customização ATS: relatório personalizado. -->

<script setup lang="ts">
import { computed, ref } from 'vue'

import Form from '#shared/components/Form/Form.vue'
import type { FormSchemaNode, FormSubmitData } from '#shared/components/Form/types.ts'

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

const FORM_ID = 'custom-report-filters'

// Trocar a key remonta o Form, que é como limpamos os campos sem manter uma
// cópia do estado interno do FormKit aqui.
const formKey = ref(0)

const schema = computed<FormSchemaNode[]>(() =>
  props.available.map(({ name, display }) => ({
    type: 'text',
    name,
    label: display,
    value: props.modelValue[name]?.value ?? '',
    outerClass: 'col-span-1',
  })),
)

const apply = (data: FormSubmitData<Record<string, string>>) => {
  const filters: RuntimeFilters = {}

  Object.entries(data).forEach(([name, value]) => {
    if (!value) return
    // 'contains' é mais útil que igualdade exata para filtro digitado à mão.
    filters[name] = { operator: 'contains', value }
  })

  emit('apply', filters)
}

const clear = () => {
  formKey.value += 1
  emit('apply', {})
}
</script>

<template>
  <div class="flex flex-col gap-3 rounded-lg bg-blue-200 p-4 dark:bg-gray-700">
    <Form
      :id="FORM_ID"
      :key="formKey"
      :schema="schema"
      form-class="grid gap-3 sm:grid-cols-2 lg:grid-cols-3"
      @submit="apply($event as FormSubmitData<Record<string, string>>)"
    />

    <div class="flex gap-2">
      <CommonButton type="submit" :form="FORM_ID" variant="submit" size="medium">
        {{ $t('Apply') }}
      </CommonButton>
      <CommonButton variant="secondary" size="medium" @click="clear">
        {{ $t('Clear') }}
      </CommonButton>
    </div>
  </div>
</template>
