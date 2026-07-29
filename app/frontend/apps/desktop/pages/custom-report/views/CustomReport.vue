<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->
<!-- Customização ATS: relatório personalizado. -->

<script setup lang="ts">
import { computed, onUnmounted, ref, watch } from 'vue'

import CommonLink from '#shared/components/CommonLink/CommonLink.vue'
import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import Form from '#shared/components/Form/Form.vue'
import type { FormFieldValue, FormSchemaNode } from '#shared/components/Form/types.ts'
import { i18n } from '#shared/i18n.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import CommonSimpleTable from '#desktop/components/CommonTable/CommonSimpleTable.vue'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'
import { useCustomReportGenerateMutation } from '#desktop/entities/custom-report/graphql/mutations/customReportGenerate.api.ts'
import { useCustomReportListQuery } from '#desktop/entities/custom-report/graphql/queries/customReportList.api.ts'
import { useCustomReportResultsQuery } from '#desktop/entities/custom-report/graphql/queries/customReportResults.api.ts'
import { useCustomReportRunsQuery } from '#desktop/entities/custom-report/graphql/queries/customReportRuns.api.ts'

import CustomReportFilters from '../components/CustomReportFilters.vue'

import type { RuntimeFilters } from '../types.ts'

const DEFAULT_FORMAT = 'csv'

const selectedReportId = ref<string>()
const format = ref(DEFAULT_FORMAT)
const page = ref(1)
const filters = ref<RuntimeFilters>({})
const filtersOpen = ref(false)

const { notify } = useNotifications()

const listQuery = new QueryHandler(useCustomReportListQuery())
const listResult = listQuery.result()
const listLoading = listQuery.loading()

const reports = computed(() => listResult.value?.customReportList ?? [])

// Valor inicial do select, separado de selectedReportId de propósito: o schema
// abaixo é computed, e se o `value` dele viesse do ref que o @changed atualiza, a
// cada escolha o Form seria remontado.
const initialReportId = ref<string>()

// Seleciona o primeiro relatório disponível para a tela não abrir vazia.
watch(reports, (value) => {
  if (selectedReportId.value || !value.length) return

  selectedReportId.value = value[0].id
  initialReportId.value = value[0].id
})

const toolbarSchema = computed<FormSchemaNode[]>(() => [
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
  if (fieldName === 'format') {
    format.value = String(newValue)
    return
  }

  if (fieldName !== 'customReportId') return

  selectedReportId.value = String(newValue)
  // Filtros e página pertencem ao relatório anterior.
  filters.value = {}
  page.value = 1
  filtersOpen.value = false
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

// --- Exportação -------------------------------------------------------------
//
// O arquivo não é gerado na requisição: um relatório grande estouraria o tempo
// e prenderia um worker. A mutation enfileira e esta lista acompanha.

const runsQuery = new QueryHandler(useCustomReportRunsQuery(() => ({ limit: 10 })))
const runsResult = runsQuery.result()

const runs = computed(() => runsResult.value?.customReportRuns ?? [])

const hasRunningExport = computed(() =>
  runs.value.some((run) => run.status === 'pending' || run.status === 'running'),
)

// Sem subscription para relatório personalizado, então o progresso vem de
// polling — e só enquanto houver geração em andamento.
let pollTimer: ReturnType<typeof setInterval> | undefined

const stopPolling = () => {
  if (!pollTimer) return
  clearInterval(pollTimer)
  pollTimer = undefined
}

watch(hasRunningExport, (running) => {
  if (!running) {
    stopPolling()
    return
  }
  if (pollTimer) return

  pollTimer = setInterval(() => runsQuery.refetch(), 4000)
})

onUnmounted(stopPolling)

const generateMutation = new MutationHandler(useCustomReportGenerateMutation())

const generate = async () => {
  if (!selectedReportId.value) return

  await generateMutation.send({
    customReportId: selectedReportId.value,
    format: format.value,
  })

  notify({
    id: 'custom-report-queued',
    type: NotificationTypes.Success,
    message: __('Report queued. You will be notified when it is ready to download.'),
  })

  runsQuery.refetch()
}

const runProgressLabel = (run: (typeof runs.value)[number]) => {
  if (run.status === 'failed') return run.errorMessage || i18n.t('Generation failed.')
  if (run.status === 'succeeded') return i18n.t('Ready')
  if (run.progressPercent === null || run.progressPercent === undefined) {
    return i18n.t('Processing…')
  }

  return `${run.progressPercent}%`
}
</script>

<template>
  <LayoutContent :breadcrumb-items="[{ label: __('Custom Report') }]" width="full">
    <template #headerRight>
      <CommonButton
        v-if="result?.enabledFilters.length"
        size="medium"
        prefix-icon="filter"
        @click="filtersOpen = !filtersOpen"
      >
        {{ $t('Filters') }}
      </CommonButton>
      <CommonButton
        variant="primary"
        size="medium"
        prefix-icon="download"
        :disabled="!selectedReportId"
        @click="generate"
      >
        {{ $t('Export') }}
      </CommonButton>
    </template>

    <div class="flex flex-col gap-4">
      <CommonLoader :loading="listLoading">
        <Form
          v-if="reports.length"
          id="custom-report-toolbar"
          :schema="toolbarSchema"
          form-class="flex flex-wrap items-end gap-3"
          @changed="onToolbarChanged"
        />
        <CommonLabel v-else>
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

      <section v-if="runs.length" class="flex flex-col gap-2">
        <CommonLabel size="small">{{ $t('Recent exports') }}</CommonLabel>

        <ul class="flex flex-col gap-1">
          <li
            v-for="run in runs"
            :key="run.id"
            class="flex flex-wrap items-center gap-3 rounded-lg bg-blue-200 px-3 py-2 dark:bg-gray-700"
          >
            <CommonLabel class="grow">{{ run.filename }}</CommonLabel>
            <CommonLabel size="small">{{ runProgressLabel(run) }}</CommonLabel>
            <CommonLink
              v-if="run.downloadable && run.downloadPath"
              :link="run.downloadPath"
              rest-api
              size="small"
            >
              {{ $t('Download') }}
            </CommonLink>
          </li>
        </ul>
      </section>
    </div>
  </LayoutContent>
</template>
