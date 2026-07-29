<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->
<!-- Customização ATS: relatório personalizado. -->

<script setup lang="ts">
import { computed, ref, watch } from 'vue'

import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'
import { i18n } from '#shared/i18n.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import CommonSimpleTable from '#desktop/components/CommonTable/CommonSimpleTable.vue'
import LayoutContent from '#desktop/components/layout/LayoutContent.vue'
import { useCustomReportListQuery } from '#desktop/entities/custom-report/graphql/queries/customReportList.api.ts'
import { useCustomReportResultsQuery } from '#desktop/entities/custom-report/graphql/queries/customReportResults.api.ts'

import CustomReportFilters from '../components/CustomReportFilters.vue'
import type { RuntimeFilters } from '../types.ts'

const selectedReportId = ref<string>()
const page = ref(1)
const filters = ref<RuntimeFilters>({})
const filtersOpen = ref(false)

const listQuery = new QueryHandler(useCustomReportListQuery())
const listResult = listQuery.result()
const listLoading = listQuery.loading()

const reports = computed(() => listResult.value?.customReportList ?? [])

// Seleciona o primeiro relatório disponível para a tela não abrir vazia.
watch(reports, (value) => {
  if (!selectedReportId.value && value.length) selectedReportId.value = value[0].id
})

const reportOptions = computed(() =>
  reports.value.map((report) => ({ value: report.id, label: report.name })),
)

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

const changeReport = (id: string) => {
  selectedReportId.value = id
  // Filtros e página pertencem ao relatório anterior.
  filters.value = {}
  page.value = 1
}

const applyFilters = (value: RuntimeFilters) => {
  filters.value = value
  page.value = 1
  filtersOpen.value = false
}

const goToPage = (target: number) => {
  if (target < 1 || target > totalPages.value) return
  page.value = target
}
</script>

<template>
  <LayoutContent :breadcrumb-items="[{ label: __('Custom Report') }]" width="full">
    <div class="flex flex-col gap-4">
      <div class="flex flex-wrap items-end gap-3">
        <CommonLoader :loading="listLoading">
          <!-- select nativo de propósito: CommonSelect é só um container de
               dropdown e depende de um slot de gatilho, o que aqui traria mais
               código do que valor para escolher um relatório. -->
          <label v-if="reportOptions.length" class="flex flex-col gap-1">
            <span class="text-sm text-stone-200 dark:text-neutral-500">{{ $t('Report') }}</span>
            <select
              :value="selectedReportId"
              class="rounded-lg bg-blue-200 px-2 py-1 text-sm text-black dark:bg-gray-700 dark:text-white"
              @change="changeReport(($event.target as HTMLSelectElement).value)"
            >
              <option v-for="option in reportOptions" :key="option.value" :value="option.value">
                {{ option.label }}
              </option>
            </select>
          </label>
          <p v-else class="text-sm text-stone-200 dark:text-neutral-500">
            {{ $t('No report available. Ask an administrator to configure one.') }}
          </p>
        </CommonLoader>

        <CommonButton
          v-if="result?.enabledFilters.length"
          size="medium"
          prefix-icon="funnel"
          @click="filtersOpen = !filtersOpen"
        >
          {{ $t('Filters') }}
        </CommonButton>
      </div>

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

          <div class="flex items-center justify-between gap-3">
            <span class="text-sm text-stone-200 dark:text-neutral-500">
              {{ i18n.t('%s record(s) found', totalCount) }}
            </span>

            <div v-if="totalPages > 1" class="flex items-center gap-2">
              <CommonButton
                size="medium"
                :disabled="result.page <= 1"
                @click="goToPage(result.page - 1)"
              >
                {{ $t('Previous') }}
              </CommonButton>
              <span class="text-sm">{{ i18n.t('Page %s of %s', result.page, totalPages) }}</span>
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
    </div>
  </LayoutContent>
</template>
