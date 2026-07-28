# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: geração assíncrona de relatório personalizado.

# Gera o arquivo do relatório fora do ciclo da requisição.
#
# HasActiveJobLock garante uma geração por usuário: sem isso, cliques repetidos
# em "gerar" enfileirariam varreduras concorrentes da base e derrubariam o
# servidor, que é justamente o que a fila existe para evitar.
class CustomReportGenerateJob < ApplicationJob
  include HasActiveJobLock

  # Intervalo de linhas entre avisos de progresso ao usuário.
  PROGRESS_INTERVAL = 2_000

  def lock_key
    "#{self.class.name}/User/#{arguments.first[:run].created_by_id}"
  end

  def perform(run:)
    user = run.created_by

    run.update!(status: 'running', processed_rows: 0)

    query   = CustomReport::Query.new(report: run.custom_report, user: user)
    columns = CustomReport::Columns.new(report: run.custom_report, user: user)

    total = query.count
    if total > query.max_rows
      return fail_run(
        run,
        format(__('The report matches %s rows, which is above the limit of %s. Please narrow the filters.'), total, query.max_rows),
        user
      )
    end

    run.update!(total_rows: total)
    notify_progress(run, user, 0, total)

    result = exporter_for(run, query, columns, user, total).call

    run.update!(
      status:         'succeeded',
      processed_rows: result[:rows],
      filesize:       result[:filesize],
      expires_at:     CustomReportRun::RETENTION.from_now,
    )

    notify_finished(run, user)
  rescue => e
    Rails.logger.error "CustomReportGenerateJob failed for run #{run&.id}: #{e.message}"
    Rails.logger.error e.backtrace&.join("\n")
    fail_run(run, e.message, run&.created_by)
    raise
  end

  private

  def exporter_for(run, query, columns, user, total)
    last_notified = 0

    on_progress = lambda do |processed|
      run.update_columns(processed_rows: processed) # rubocop:disable Rails/SkipsModelValidations
      next if processed - last_notified < PROGRESS_INTERVAL

      last_notified = processed
      notify_progress(run, user, processed, total)
    end

    # Fase 1 gera apenas CSV. xlsx entra na fase 2, com teto de linhas, porque
    # ExcelSheet monta a planilha em memória.
    CustomReport::Exporter::Csv.new(run:, query:, columns:, on_progress:)
  end

  def fail_run(run, message, user)
    return if !run

    run.update!(status: 'failed', error: message)
    notify_finished(run, user)
    nil
  end

  # A UI legada não recebe as subscriptions GraphQL usadas pelo bulk update do
  # 7.2 (aquelas só existem na Desktop View), então o progresso vai pelo mesmo
  # canal WebSocket que o controle de tempo/pausas já usa.
  def notify_progress(run, user, processed, total)
    return if !user

    PushMessages.send_to(user.id, {
                           event: 'CustomReportRun:progress',
                           data:  {
                             id:             run.id,
                             status:         run.status,
                             processed_rows: processed,
                             total_rows:     total,
                           }
                         })
  end

  def notify_finished(run, user)
    return if !user

    PushMessages.send_to(user.id, {
                           event: 'CustomReportRun:finished',
                           data:  {
                             id:       run.id,
                             status:   run.status,
                             error:    run.error,
                             filesize: run.filesize,
                           }
                         })

    OnlineNotification.add(
      user_id:       user.id,
      kind:          'custom_report',
      seen:          false,
      data:          { custom_report_id: run.custom_report_id, status: run.status },
      created_by_id: 1, # aparece como do sistema, com o logo da instância
    )
  end
end
