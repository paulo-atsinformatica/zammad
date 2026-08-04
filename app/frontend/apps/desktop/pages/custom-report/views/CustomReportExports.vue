<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->
<!-- Customização ATS: relatório personalizado. -->

<script setup lang="ts">
import { computed, onUnmounted, watch } from 'vue'
import { useRouter } from 'vue-router'

import CommonLink from '#shared/components/CommonLink/CommonLink.vue'
import { i18n } from '#shared/i18n.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import { useCustomReportRunsQuery } from '#desktop/entities/custom-report/graphql/queries/customReportRuns.api.ts'

import CustomReportPage from '../components/CustomReportPage.vue'

const router = useRouter()

const goToReport = () => router.push({ name: 'CustomReport' })

const runsQuery = new QueryHandler(useCustomReportRunsQuery(() => ({ limit: 50 })))
const runsResult = runsQuery.result()
const runsLoading = runsQuery.loading()

const runs = computed(() => runsResult.value?.customReportRuns ?? [])

const hasRunning = computed(() =>
  runs.value.some((run) => run.status === 'pending' || run.status === 'running'),
)

// Sem subscription para esta feature, então o progresso vem de polling — e só
// enquanto houver geração em andamento.
let pollTimer: ReturnType<typeof setInterval> | undefined

const stopPolling = () => {
  if (!pollTimer) return

  clearInterval(pollTimer)
  pollTimer = undefined
}

watch(hasRunning, (running) => {
  if (!running) {
    stopPolling()
    return
  }
  if (pollTimer) return

  pollTimer = setInterval(() => runsQuery.refetch(), 4000)
})

onUnmounted(stopPolling)

const statusLabel = (run: (typeof runs.value)[number]) => {
  if (run.status === 'failed') return run.errorMessage || i18n.t('Generation failed.')
  if (run.status === 'succeeded') return i18n.t('Ready')
  if (run.progressPercent === null || run.progressPercent === undefined) {
    return i18n.t('Processing…')
  }

  return `${run.progressPercent}%`
}

// Lista e não CommonSimpleTable: o grid não renderiza componentes numa célula
// (useCellContent só conhece texto e data), e cada linha precisa do link de
// download.
</script>

<template>
  <CustomReportPage :title="__('Export queue')">
    <template #actions>
      <CommonButton size="medium" prefix-icon="arrow-bar-left" @click="goToReport">
        {{ $t('Back to the report') }}
      </CommonButton>
    </template>

    <CommonLoader :loading="runsLoading">
      <CommonLabel v-if="!runs.length">
        {{ $t('No export yet. Generate one from the report screen.') }}
      </CommonLabel>

      <ul v-else class="flex flex-col gap-1">
        <li
          v-for="run in runs"
          :key="run.id"
          class="grid items-center gap-3 rounded-lg bg-blue-200 px-3 py-2 sm:grid-cols-[2fr_1fr_1fr_auto] dark:bg-gray-700"
        >
          <CommonLabel class="truncate">{{ run.filename }}</CommonLabel>
          <CommonLabel size="small" class="truncate">{{ run.customReport.name }}</CommonLabel>
          <CommonLabel size="small">{{ statusLabel(run) }}</CommonLabel>
          <CommonLink
            v-if="run.downloadable && run.downloadPath"
            :link="run.downloadPath"
            rest-api
            size="small"
          >
            {{ $t('Download') }}
          </CommonLink>
          <span v-else />
        </li>
      </ul>
    </CommonLoader>
  </CustomReportPage>
</template>
