<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->
<!-- Customização ATS: relatório personalizado. -->

<script setup lang="ts">
import { computed, ref, watch } from 'vue'

import Form from '#shared/components/Form/Form.vue'
import type { FormFieldValue, FormSchemaNode } from '#shared/components/Form/types.ts'
import type { EnumOrderDirection } from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'

import CommonActionMenu from '#desktop/components/CommonActionMenu/CommonActionMenu.vue'
import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import CommonAdvancedTable from '#desktop/components/CommonTable/CommonAdvancedTable.vue'
import { useCustomReportListQuery } from '#desktop/entities/custom-report/graphql/queries/customReportList.api.ts'
import { useCustomReportResultsQuery } from '#desktop/entities/custom-report/graphql/queries/customReportResults.api.ts'

import CustomReportFilters from '../components/CustomReportFilters.vue'
import CustomReportPage from '../components/CustomReportPage.vue'
import CustomReportSummary from '../components/CustomReportSummary.vue'
import { useCustomReportExport } from '../composables/useCustomReportExport.ts'

import type { AvailableFilter, ReportSummary, RuntimeFilters } from '../types.ts'

const ALL_SCOPES = 'all'

const selectedReportId = ref<string>()
const scope = ref(ALL_SCOPES)
const page = ref(1)
const filters = ref<RuntimeFilters>({})

const { generate, goToExports } = useCustomReportExport()

const listQuery = new QueryHandler(
  useCustomReportListQuery(() => ({
    // 'all' não é um recorte; o backend trata a ausência do argumento como
    // "tudo que o usuário enxerga".
    scope: scope.value === ALL_SCOPES ? undefined : scope.value,
  })),
)
const listResult = listQuery.result()
const listLoading = listQuery.loading()
const listError = listQuery.operationError()

const reports = computed(() => listResult.value?.customReportList ?? [])

const selectReport = (id: string | undefined) => {
  selectedReportId.value = id
  // Filtros e página pertencem ao relatório anterior.
  filters.value = {}
  page.value = 1
}

// Seleciona o primeiro disponível para a tela não abrir vazia, e reage a uma
// troca de visibilidade que tire o relatório atual da lista.
//
// Observa o resultado da query, e não `reports`: a política é cache-and-network,
// então trocar o recorte zera `listResult` enquanto a resposta não chega. Se
// observássemos `reports` (que vira `[]` nesse intervalo), a escolha atual seria
// descartada no meio do refetch e a tela ficaria vazia até o usuário clicar de
// novo. Enquanto o resultado for indefinido, mantém o que já está selecionado.
watch(listResult, (value) => {
  const list = value?.customReportList
  if (!list) return

  if (list.some((report) => report.id === selectedReportId.value)) return

  selectReport(list[0]?.id)
})

// Schema estático (não computed) de propósito: um schema recriado faz o FormKit
// reaplicar o `value` de cada campo, e o recorte escolhido voltaria ao padrão a
// cada refetch da lista.
//
// A escolha do relatório saiu daqui e virou a lista da barra lateral, no mesmo
// modelo da Visão Geral — um select escondia os relatórios atrás de um clique e
// não deixava ver quais existem.
const scopeSchema: FormSchemaNode[] = [
  {
    type: 'select',
    name: 'scope',
    label: __('Show'),
    value: ALL_SCOPES,
    outerClass: 'grow',
    props: {
      options: [
        { value: ALL_SCOPES, label: __('All') },
        { value: 'group', label: __('My groups') },
        { value: 'personal', label: __('Personal view') },
      ],
    },
  },
]

const onScopeChanged = (fieldName: string, newValue: FormFieldValue) => {
  if (fieldName !== 'scope') return

  scope.value = String(newValue)
}

// A ordenação é aplicada no banco, não na página carregada — senão ordenaria só
// as 50 linhas visíveis. CustomReport::Query#ordered só aceita coluna real da
// tabela, então um nome inesperado cai para `id` em vez de ir ao ORDER BY.
//
// Declarados antes da query porque entram nas variáveis dela.
const orderBy = ref<string>()
const orderDirection = ref<EnumOrderDirection>()

const resultsQuery = new QueryHandler(
  useCustomReportResultsQuery(
    () => ({
      customReportId: selectedReportId.value as string,
      page: page.value,
      filters: filters.value,
      orderBy: orderBy.value,
      orderDirection: orderDirection.value,
    }),
    // Sem relatório escolhido não há o que consultar.
    () => ({ enabled: Boolean(selectedReportId.value) }),
  ),
)

const resultsResult = resultsQuery.result()
// loadingWithoutCachedResult (e não loading) para o grid já carregado não piscar
// a cada refetch — só mostra o loader quando não há nada para exibir.
const resultsLoading = resultsQuery.loadingWithoutCachedResult()
const resultsError = resultsQuery.operationError()

const result = computed(() => resultsResult.value?.customReportResults)

// Sem isto, qualquer falha do GraphQL virava tela em branco silenciosa: o
// template só testava `v-if="result"` e não havia ramo de erro.
const errorMessage = computed(() => listError.value?.message || resultsError.value?.message)

// CommonAdvancedTable (e não CommonSimpleTable) porque é o componente que traz
// redimensionar coluna arrastando e ordenar clicando no cabeçalho. Ele recebe os
// nomes em `headers` e a descrição de cada coluna em `attributes`.
const tableHeaders = computed(() => result.value?.columns.map((column) => column.name) ?? [])

// dataType 'input' para todas: o backend já entrega os valores formatados como
// texto (datas em ISO, relações pelo nome), então não há tipo a interpretar aqui.
const tableAttributes = computed(
  () =>
    result.value?.columns.map((column) => ({
      name: column.name,
      label: column.display,
      dataType: 'input',
      headerPreferences: { noResize: false, truncate: true },
      columnPreferences: {},
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

// Só existe quando o relatório define totalizadores.
const summary = computed(() => (result.value?.summary ?? undefined) as ReportSummary | undefined)

// O GraphQL tipa `type` como String; o conjunto fechado de valores é garantido
// por CustomReport::FilterDefinition, então o estreitamento acontece aqui, na
// fronteira, em vez de espalhar cast pelo componente.
const availableFilters = computed(
  () => (result.value?.enabledFilters ?? []) as unknown as AvailableFilter[],
)

const applyFilters = (value: RuntimeFilters) => {
  filters.value = value
  page.value = 1
}

const goToPage = (target: number) => {
  if (target < 1 || target > totalPages.value) return

  page.value = target
}

const sortByColumn = (column: string, direction: EnumOrderDirection) => {
  orderBy.value = column
  orderDirection.value = direction
  page.value = 1
}

const exportReport = (format: string) => {
  if (!selectedReportId.value) return

  generate(selectedReportId.value, format)
}

// O formato é escolhido no clique, num menu, em vez de ocupar espaço permanente
// na barra: quem só consulta o relatório nunca precisa dele.
const exportActions = computed<MenuItem[]>(() => [
  {
    key: 'csv',
    label: __('Export as CSV'),
    icon: 'download',
    // CSV primeiro por ser o formato sem teto de linhas; o xlsx falha acima do
    // limite do próprio formato (ver CustomReport::Exporter::Xlsx::MAX_ROWS).
    onClick: () => exportReport('csv'),
  },
  {
    key: 'xlsx',
    label: __('Export as Excel (xlsx)'),
    icon: 'download',
    onClick: () => exportReport('xlsx'),
  },
])
</script>

<template>
  <CustomReportPage :title="__('Custom Report')" with-sidebar>
    <template #actions>
      <CommonButton size="medium" prefix-icon="list" @click="goToExports">
        {{ $t('Export queue') }}
      </CommonButton>
      <CommonActionMenu
        :actions="exportActions"
        :disabled="!selectedReportId"
        no-single-action-mode
        button-size="medium"
        default-icon="download"
        default-button-variant="primary"
        :custom-menu-button-label="$t('Export report')"
      />
    </template>

    <template #sidebar>
      <!--
        O Form fica fora do CommonLoader de propósito: `loading` volta a ser
        verdadeiro a cada refetch da lista, e o loader desmontaria o próprio
        campo que acabou de ser usado — trocar o recorte fazia o seletor
        desaparecer.
      -->
      <div class="mb-3 flex items-end gap-2">
        <Form
          id="custom-report-scope"
          :schema="scopeSchema"
          form-class="grow"
          @changed="onScopeChanged"
        />
      </div>

      <CommonLabel v-if="!listLoading && !reports.length" size="small">
        {{ $t('No report available for this visibility.') }}
      </CommonLabel>

      <ul v-else class="flex flex-col gap-1">
        <li v-for="report in reports" :key="report.id">
          <button
            type="button"
            class="w-full rounded-lg px-3 py-2 text-start text-sm hover:bg-blue-600 hover:text-white"
            :class="
              report.id === selectedReportId
                ? 'bg-blue-800 text-white'
                : 'text-gray-100 dark:text-neutral-400'
            "
            @click="selectReport(report.id)"
          >
            {{ report.name }}
          </button>
        </li>
      </ul>
    </template>

    <CommonAlert v-if="errorMessage" variant="danger" class="mb-3">
      {{ $t(errorMessage) }}
    </CommonAlert>

    <!-- Sempre visíveis: esconder os filtros atrás de um botão obrigava um
         clique extra em toda consulta e escondia quais filtros existem. -->
    <CustomReportFilters
      v-if="availableFilters.length"
      :available="availableFilters"
      :model-value="filters"
      class="mb-3"
      @apply="applyFilters"
    />

    <CommonLoader :loading="resultsLoading">
      <template v-if="result">
        <CustomReportSummary v-if="summary" :summary="summary" />

        <!-- A key remonta a tabela ao trocar de relatório. Sem ela o componente
             sobrevive à troca com as larguras de coluna e o estado de cabeçalho
             do relatório anterior, cujas colunas nem existem no novo. -->
        <CommonAdvancedTable
          :key="selectedReportId"
          :caption="$t('Custom report results')"
          :headers="tableHeaders"
          :attributes="tableAttributes"
          :items="tableItems"
          :total-items-count="totalCount"
          :order-by="orderBy"
          :order-direction="orderDirection"
          :table-id="`custom-report-${selectedReportId}`"
          :storage-key-id="`custom-report-${selectedReportId}`"
          @sort="sortByColumn"
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
