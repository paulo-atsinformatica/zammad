<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->
<!-- Customização ATS: relatório personalizado. -->

<script setup lang="ts">
import { computed, ref } from 'vue'

import Form from '#shared/components/Form/Form.vue'
import type { FormSchemaNode, FormSubmitData } from '#shared/components/Form/types.ts'
import { i18n } from '#shared/i18n.ts'

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
  // Data é sempre período. 'in range' recebe [de, até] e o Selector::Sql cobre
  // os três casos (BETWEEN, só >= ou só <=), então filtrar um dia só é pôr a
  // mesma data nos dois campos.
  date: 'in range',
  text: 'contains',
} as const

// Tipos cujo valor é um id e que o selector espera receber como lista.
const ID_TYPES = ['select', 'agent', 'customer', 'organization', 'boolean'] as const

// Um filtro de data vira dois campos no formulário. Os sufixos os reagrupam num
// único filtro na hora de aplicar — ver `apply`.
const DATE_FROM_SUFFIX = '__from'
const DATE_TILL_SUFFIX = '__till'

const fieldFor = (
  filter: AvailableFilter,
  shared: { name: string; label: string; outerClass: string },
): FormSchemaNode => {
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
    case 'number':
      return { ...shared, type: 'number' }
    default:
      return { ...shared, type: 'text' }
  }
}

const fieldsFor = (filter: AvailableFilter): FormSchemaNode[] => {
  const shared = {
    name: filter.name,
    label: filter.display,
    outerClass: 'col-span-1',
  }

  if (filter.type !== 'date') return [fieldFor(filter, shared)]

  // `display` já vem traduzido do backend, então o rótulo composto é montado
  // aqui: mandá-lo inteiro para o FormKit traduzir não acharia entrada nenhuma
  // e o sufixo ficaria em inglês.
  return [
    {
      ...shared,
      name: `${filter.name}${DATE_FROM_SUFFIX}`,
      label: i18n.t('%s (from)', filter.display),
      type: 'date',
    },
    {
      ...shared,
      name: `${filter.name}${DATE_TILL_SUFFIX}`,
      label: i18n.t('%s (until)', filter.display),
      type: 'date',
    },
  ]
}

const schema = computed<FormSchemaNode[]>(() => props.available.flatMap(fieldsFor))

const typeByName = computed(
  () => new Map(props.available.map((filter) => [filter.name, filter.type])),
)

// Os dois campos de um filtro de data voltam separados do formulário e são
// remontados aqui num único `in range`. Um lado vazio é intencional: significa
// "sem limite deste lado", e o backend resolve como >= ou <=.
const dateRangeFilters = (data: Record<string, unknown>): RuntimeFilters => {
  const filters: RuntimeFilters = {}

  props.available.forEach((filter) => {
    if (filter.type !== 'date') return

    const from = String(data[`${filter.name}${DATE_FROM_SUFFIX}`] ?? '').trim()
    const till = String(data[`${filter.name}${DATE_TILL_SUFFIX}`] ?? '').trim()
    if (!from && !till) return

    filters[filter.name] = { operator: OPERATORS.date, value: [from, till] }
  })

  return filters
}

const apply = (data: FormSubmitData<Record<string, unknown>>) => {
  const filters: RuntimeFilters = dateRangeFilters(data)

  Object.entries(data).forEach(([name, value]) => {
    if (value === undefined || value === null || value === '') return

    // Campos de data já foram tratados acima, pelo nome do filtro.
    if (name.endsWith(DATE_FROM_SUFFIX) || name.endsWith(DATE_TILL_SUFFIX)) return

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
