# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: relatório personalizado.

module Gql::Queries
  class CustomReport::List < BaseQuery

    description 'Saved custom reports the current user may open'

    argument :visibility, String, required: false,
             description: 'Restrict to one visibility level: global, group or personal'

    type [Gql::Types::CustomReportType, { null: false }], null: false

    requires_permission 'report.custom'

    def resolve(visibility: nil)
      reports = ::CustomReport.visible_to(context.current_user)
      reports = restrict(reports, visibility)

      reports.reorder(name: :asc)
    end

    private

    def restrict(reports, visibility)
      case visibility
      when 'global', 'group'
        reports.where(visibility:)
      when 'personal'
        # Pessoal é sempre "meu": um relatório pessoal de outra pessoa não é
        # visível de todo modo, mas ser explícito evita depender disso.
        reports.where(visibility: 'personal', created_by_id: context.current_user.id)
      else
        reports
      end
    end
  end
end
