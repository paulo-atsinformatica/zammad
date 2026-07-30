<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->
<!-- Customização ATS: relatório personalizado. -->

<script setup lang="ts">
import { computed, ref, watch } from 'vue'

import Form from '#shared/components/Form/Form.vue'
import type { FormFieldValue, FormSchemaNode } from '#shared/components/Form/types.ts'
import { i18n } from '#shared/i18n.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import CommonSimpleTable from '#desktop/components/CommonTable/CommonSimpleTable.vue'
import { useCustomReportListQuery } from '#desktop/entities/custom-report/graphql/queries/customReportList.api.ts'
import { useCustomReportResultsQuery } from '#desktop/entities/custom-report/graphql/queries/customReportResults.api.ts'

import CustomReportFilters from '../components/CustomReportFilters.vue'
import CustomReportPage from '../components/CustomReportPage.vue'
import { useCustomReportExport } from '../composables/useCustomReportExport.ts'

import type { RuntimeFilters } from '../types.ts'

const DEFAULT_FORMAT = 'csv'
const ALL_VISIBILITIES = 'all'

const selectedReportId = ref<string>()
const format = ref(DEFAULT_FORMAT)
const visibility = ref(ALL_VISIBILITIES)
const page = ref(1)
const filters = ref<RuntimeFilters>({})
const filtersOpen = ref(false)

const { generate, goToExports } = useCustomReportExport()

const listQuery = new QueryHandler(
  useCustomReportListQuery(() => ({
    // 'all' não é um nível de visibilidade; o backend trata a ausência do
    // argumento como "todos".
    visibility: visibility.value === ALL_VISIBILITIES ? undefined : visibility.value,
  })),
)
const listResult = listQuery.result()
const listLoading = listQuery.loading()

const reports = computed(() => listResult.value?.customReportList ?? [])

// Valor inicial do select, separado de selectedReportId de propósito: o schema
// abaixo é computed, e se o `value` dele viesse do ref que o @changed atualiza, a
// cada escolha o Form seria remontado.
const initialReportId = ref<string>()

const selectReport = (id: string | undefined) => {
  selectedReportId.value = id
  initialReportId.value = id
  // Filtros e página pertencem ao relatório anterior.
  filters.value = {}
  page.value = 1
  filtersOpen.value = false
}

// Seleciona o primeiro disponível para a tela não abrir vazia, e reage a uma
// troca de visibilidade que tire o relatório atual da lista.
watch(reports, (value) => {
  if (value.some((report) => report.id === selectedReportId.value)) return

  selectReport(value[0]?.id)
})

const toolbarSchema = computed<FormSchemaNode[]>(() => [
  {
    type: 'select',
    name: 'visibility',
    label: __('Visible for'),
    value: ALL_VISIBILITIES,
    outerClass: 'min-w-48',
    props: {
      options: [
        { value: ALL_VISIBILITIES, label: __('All') },
        { value: 'global', label: __('Everyone') },
        { value: 'group', label: __('Members of selected groups') },
        { value: 'personal', label: __('Only me') },
      ],
    },
  },
  {
    type: 'select',
    name: 'customReportId',
    label: __('Report'),
    value: initialReportId.value,
    outerClass: 'min-w-64',
    props: {
      options: reports.value.map((report) => ({ value: report.id, label: report.name })),
      // Nomes de relatório são dados do usuário, não strings do catálogo.
      noOptionsLabelTranslation: true,
    },
  },
  {
    type: 'select',
    name: 'format',
    label: __('Export format'),
    value: DEFAULT_FORMAT,
    outerClass: 'min-w-40',
    props: {
      options: [
        { value: 'csv', label: __('CSV') },
        { value: 'xlsx', label: __('Excel (xlsx)') },
      ],
    },
  },
])

const onToolbarChanged = (fieldName: string, newValue: FormFieldValue) => {
  switch (fieldName) {
    case 'format':
      format.value = String(newValue)
      break
    case 'visibility':
      visibility.value = String(newValue)
      break
    case 'customReportId':
      selectReport(String(newValue))
      break
    default:
      break
  }
}

const resultsQuery = new QueryHandler(
  useCustomReportResultsQuery(
    () => ({
      customReportId: selectedReportId.value as string,
      page: page.value,
      filters: filters.value,
    }),
    // Sem relatório escolhido não há o que consultar.
    () => ({ enabled: Boolean(selectedReportId.value) }),
  ),
)

const resultsResult = resultsQuery.result()
const resultsLoading = resultsQuery.loading()

const result = computed(() => resultsResult.value?.customReportResults)

// O grid espera { key, label }; a API entrega { name, display } já traduzido.
const tableHeaders = computed(
  () =>
    result.value?.columns.map((column) => ({
      key: column.name,
      label: column.display,
      truncate: true,
    })) ?? [],
)

// Cada linha vira um objeto plano com as colunas na raiz, que é o formato do
// grid. O id vem separado para o grid poder identificar a linha.
const tableItems = computed(
  () =>
    result.value?.rows.map((row) => ({
      id: row.id,
      ...(row.values as Record<string, unknown>),
    })) ?? [],
)

const totalPages = computed(() => result.value?.totalPages ?? 0)
const totalCount = computed(() => result.value?.totalCount ?? 0)

const applyFilters = (value: RuntimeFilters) => {
  filters.value = value
  page.value = 1
}

const goToPage = (target: number) => {
  if (target < 1 || target > totalPages.value) return

  page.value = target
}

const exportReport = () => {
  if (!selectedReportId.value) return

  generate(selectedReportId.value, format.value)
}
</script>

<template>
  <CustomReportPage :title="__('Custom Report')">
    <template #actions>
      <CommonButton
        v-if="result?.enabledFilters.length"
        size="medium"
        prefix-icon="filter"
        @click="filtersOpen = !filtersOpen"
      >
        {{ $t('Filters') }}
      </CommonButton>
      <CommonButton size="medium" prefix-icon="list" @click="goToExports">
        {{ $t('Report exports') }}
      </CommonButton>
      <CommonButton
        variant="primary"
        size="medium"
        prefix-icon="download"
        :disabled="!selectedReportId"
        @click="exportReport"
      >
        {{ $t('Export') }}
      </CommonButton>
    </template>

    <CommonLoader :loading="listLoading">
      <Form
        id="custom-report-toolbar"
        :schema="toolbarSchema"
        form-class="flex flex-wrap items-end gap-3"
        @changed="onToolbarChanged"
      />
      <CommonLabel v-if="!reports.length">
        {{ $t('No report available. Ask an administrator to configure one.') }}
      </CommonLabel>
    </CommonLoader>

    <CustomReportFilters
      v-if="filtersOpen && result"
      :available="result.enabledFilters"
      :model-value="filters"
      @apply="applyFilters"
    />

    <CommonLoader :loading="resultsLoading">
      <template v-if="result">
        <CommonSimpleTable
          :caption="$t('Custom report results')"
          :headers="tableHeaders"
          :items="tableItems"
        />

        <div class="mt-3 flex items-center justify-between gap-3">
          <CommonLabel size="small">
            {{ i18n.t('%s record(s) found', totalCount) }}
          </CommonLabel>

          <div v-if="totalPages > 1" class="flex items-center gap-2">
            <CommonButton
              size="medium"
              :disabled="result.page <= 1"
              @click="goToPage(result.page - 1)"
            >
              {{ $t('Previous') }}
            </CommonButton>
            <CommonLabel size="small">
              {{ i18n.t('Page %s of %s', result.page, totalPages) }}
            </CommonLabel>
            <CommonButton
              size="medium"
              :disabled="result.page >= totalPages"
              @click="goToPage(result.page + 1)"
            >
              {{ $t('Next') }}
            </CommonButton>
          </div>
        </div>
      </template>
    </CommonLoader>
  </CustomReportPage>
</template>
