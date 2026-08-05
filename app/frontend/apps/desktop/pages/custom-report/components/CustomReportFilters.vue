<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->
<!-- Customização ATS: relatório personalizado. -->

<script setup lang="ts">
import { computed, ref } from 'vue'

import Form from '#shared/components/Form/Form.vue'
import type { FormSchemaNode, FormSubmitData } from '#shared/components/Form/types.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'

import type { AvailableFilter, RuntimeFilter, RuntimeFilters } from '../types.ts'

interface Props {
  // Apenas os atributos que o relatório habilitou, com o tipo de controle já
  // resolvido pelo backend. A tela não decide o que pode ser filtrado.
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

// Operador por tipo. Precisa casar com
// CustomReport::FilterDefinition::OPERATORS_BY_TYPE — o backend descarta o que
// não estiver permitido para o tipo.
const OPERATORS = {
  select: 'is',
  agent: 'is',
  customer: 'is',
  organization: 'is',
  number: 'is',
  boolean: 'is',
  date: 'after (absolute)',
  text: 'contains',
} as const

// Tipos cujo valor é um id e que o selector espera receber como lista.
const ID_TYPES = ['select', 'agent', 'customer', 'organization', 'boolean'] as const

const fieldFor = (filter: AvailableFilter): FormSchemaNode => {
  const shared = {
    name: filter.name,
    label: filter.display,
    outerClass: 'col-span-1',
  }

  switch (filter.type) {
    case 'select':
      return {
        ...shared,
        type: 'select',
        props: {
          options: filter.options.map(({ value, label }) => ({ value, label })),
          clearable: true,
          // Rótulos de estado e prioridade já vêm traduzidos do backend;
          // nomes de grupo são dados do usuário.
          noOptionsLabelTranslation: true,
        },
      }
    case 'boolean':
      return {
        ...shared,
        type: 'select',
        props: {
          options: [
            { value: 'true', label: __('yes') },
            { value: 'false', label: __('no') },
          ],
          clearable: true,
        },
      }
    // Campos de busca do próprio Zammad: o usuário digita e escolhe na lista,
    // e o valor que sai já é o id — que é o que a coluna *_id compara.
    case 'agent':
    case 'customer':
    case 'organization':
      return { ...shared, type: filter.type, props: { clearable: true } }
    case 'date':
      return { ...shared, type: 'date' }
    case 'number':
      return { ...shared, type: 'number' }
    default:
      return { ...shared, type: 'text' }
  }
}

const schema = computed<FormSchemaNode[]>(() => props.available.map(fieldFor))

const typeByName = computed(
  () => new Map(props.available.map((filter) => [filter.name, filter.type])),
)

const apply = (data: FormSubmitData<Record<string, unknown>>) => {
  const filters: RuntimeFilters = {}

  Object.entries(data).forEach(([name, value]) => {
    if (value === undefined || value === null || value === '') return

    const type = typeByName.value.get(name) ?? 'text'

    // Os campos de busca podem devolver lista quando permitem múltipla escolha.
    const values = Array.isArray(value) ? value : [value]
    if (!values.length) return

    // O selector do Zammad espera lista de valores para 'is'.
    const filter: RuntimeFilter = {
      operator: OPERATORS[type],
      value: (ID_TYPES as readonly string[]).includes(type)
        ? values.map((entry) => String(entry))
        : String(value),
    }

    filters[name] = filter
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
      @submit="apply($event as FormSubmitData<Record<string, unknown>>)"
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
