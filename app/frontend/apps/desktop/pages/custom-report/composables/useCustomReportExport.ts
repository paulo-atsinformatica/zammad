// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
// Customização ATS: relatório personalizado.

import { onUnmounted, ref } from 'vue'
import { useRouter } from 'vue-router'

import { NotificationTypes } from '#shared/components/CommonNotifications/types.ts'
import { useNotifications } from '#shared/components/CommonNotifications/useNotifications.ts'
import MutationHandler from '#shared/server/apollo/handler/MutationHandler.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'

import { useCustomReportGenerateMutation } from '#desktop/entities/custom-report/graphql/mutations/customReportGenerate.api.ts'
import { useCustomReportRunsQuery } from '#desktop/entities/custom-report/graphql/queries/customReportRuns.api.ts'

// Id fixo com unique: cada atualização de progresso substitui a notificação
// anterior em vez de empilhar uma nova.
const NOTIFICATION_ID = 'custom-report-export'
const POLL_INTERVAL_MS = 3000

// O arquivo não é gerado na requisição: um relatório grande estouraria o tempo e
// prenderia um worker. A mutation enfileira, e o acompanhamento acontece aqui.
export const useCustomReportExport = () => {
  const router = useRouter()
  const { notify } = useNotifications()

  const trackedRunId = ref<string>()

  const runsQuery = new QueryHandler(
    useCustomReportRunsQuery(
      () => ({ limit: 5 }),
      // Só consulta enquanto existe uma geração sendo acompanhada.
      () => ({ enabled: Boolean(trackedRunId.value) }),
    ),
  )

  let pollTimer: ReturnType<typeof setInterval> | undefined

  const stopPolling = () => {
    if (!pollTimer) return

    clearInterval(pollTimer)
    pollTimer = undefined
  }

  onUnmounted(stopPolling)

  const goToExports = () => router.push({ name: 'CustomReportExports' })

  const notifyRunning = (filename: string, processed?: number | null, total?: number | null) => {
    notify({
      id: NOTIFICATION_ID,
      unique: true,
      persistent: true,
      type: NotificationTypes.Info,
      message: __('Generating |%s|…'),
      messagePlaceholder: [filename],
      // Progresso só entra quando a contagem inicial terminou; antes disso não
      // há total para desenhar a barra.
      ...(total
        ? { currentProgress: processed ?? 0, maxProgress: total }
        : {}),
      actionLabel: __('Show'),
      actionCallback: goToExports,
    })
  }

  const notifyFinished = (status: string) => {
    const failed = status === 'failed'

    notify({
      id: NOTIFICATION_ID,
      unique: true,
      persistent: true,
      type: failed ? NotificationTypes.Error : NotificationTypes.Success,
      message: failed
        ? __('Custom report generation failed.')
        : __('Your custom report is ready to download.'),
      actionLabel: failed ? __('Show') : __('Download'),
      actionCallback: goToExports,
    })
  }

  const checkProgress = async () => {
    // refetch devolve { data, error }, não o resultado direto.
    const result = await runsQuery.refetch()
    const run = result?.data?.customReportRuns?.find((item) => item.id === trackedRunId.value)

    if (!run) return

    if (run.status === 'succeeded' || run.status === 'failed') {
      stopPolling()
      trackedRunId.value = undefined
      notifyFinished(run.status)
      return
    }

    notifyRunning(run.filename ?? '', run.processedRows, run.totalRows)
  }

  const generateMutation = new MutationHandler(useCustomReportGenerateMutation())

  const generate = async (customReportId: string, format: string) => {
    const result = await generateMutation.send({ customReportId, format })
    const run = result?.customReportGenerate?.customReportRun

    if (!run) return

    trackedRunId.value = run.id
    notifyRunning(run.filename ?? '')

    stopPolling()
    pollTimer = setInterval(checkProgress, POLL_INTERVAL_MS)
  }

  return { generate, goToExports }
}
