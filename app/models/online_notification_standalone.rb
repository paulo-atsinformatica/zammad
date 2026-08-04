# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class OnlineNotificationStandalone < ApplicationModel
  # Customização ATS: 'custom_report' acrescentado para a notificação de
  # relatório personalizado pronto (ver CustomReportGenerateJob).
  validates :kind, inclusion: { in: %w[bulk_job kb_answer_generation_failed custom_report] }

  BulkJobData = Data.define(:total, :failed_count)
  KbAnswerGenerationFailedData = Data.define(:error_message, :ticket_title)

  # Customização ATS
  CustomReportData = Data.define(:custom_report_id, :status)
end
