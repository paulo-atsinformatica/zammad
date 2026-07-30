<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->
<!-- Customização ATS: totalizadores do relatório personalizado. -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonSimpleTable from '#desktop/components/CommonTable/CommonSimpleTable.vue'

import type { ReportSummary } from '../types.ts'

interface Props {
  summary: ReportSummary
}

const props = defineProps<Props>()

// Agrupamentos primeiro, funções depois — mesma ordem em que o backend monta as
// linhas.
const tableHeaders = computed(() => [
  ...props.summary.groupBy.map((column) => ({
    key: column.name,
    label: column.display,
    truncate: true,
  })),
  ...props.summary.aggregations.map((aggregation) => ({
    key: aggregation.name,
    label: aggregation.display,
    alignContent: 'right' as const,
  })),
])

const tableItems = computed(() => {
  const rows = props.summary.rows.map((row, index) => ({
    id: `group-${index}`,
    ...(row.groups as Record<string, unknown>),
    ...(row.values as Record<string, unknown>),
  }))

  const totals = props.summary.totals as Record<string, unknown>
  if (!Object.keys(totals).length) return rows

  // Linha de total geral no fim, com o rótulo na primeira coluna de agrupamento.
  const firstGroup = props.summary.groupBy[0]?.name

  return [
    ...rows,
    {
      id: 'grand-total',
      ...(firstGroup ? { [firstGroup]: '∑' } : {}),
      ...totals,
    },
  ]
})
</script>

<template>
  <section class="flex flex-col gap-2">
    <CommonLabel size="small">{{ $t('Totals') }}</CommonLabel>

    <CommonSimpleTable
      :caption="$t('Totals')"
      :headers="tableHeaders"
      :items="tableItems"
    />
  </section>
</template>
