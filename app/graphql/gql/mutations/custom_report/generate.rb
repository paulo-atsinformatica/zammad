# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: relatório personalizado.

module Gql::Mutations
  class CustomReport::Generate < BaseMutation

    description 'Queue the generation of an exportable file for a custom report'

    argument :custom_report_id, GraphQL::Types::ID, description: 'Custom report to export'
    argument :format, String, required: false, description: 'csv or xlsx. Defaults to csv.'

    field :custom_report_run, Gql::Types::CustomReportRunType, description: 'The queued run'

    requires_permission 'report.custom'

    def resolve(custom_report_id:, format: nil)
      report = fetch_report(custom_report_id)

      { custom_report_run: ::CustomReportRun.enqueue!(report: report, format: format) }
    end

    private

    # Mesma regra da query de resultados: um relatório que o usuário não enxerga
    # responde como inexistente, para não revelar que existe.
    def fetch_report(custom_report_id)
      report = Gql::ZammadSchema.verified_object_from_id(custom_report_id, type: ::CustomReport)
      raise ActiveRecord::RecordNotFound, "Could not find CustomReport #{custom_report_id}" if !report.visible_to?(context.current_user)

      report
    end
  end
end
