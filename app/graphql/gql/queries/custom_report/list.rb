# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: relatório personalizado.

module Gql::Queries
  class CustomReport::List < BaseQuery

    description 'Saved custom reports the current user may open'

    argument :scope, String, required:    false,
                             description: 'Restrict the list: group (shared with a group I read) or personal (only mine)'

    type [Gql::Types::CustomReportType, { null: false }], null: false

    requires_permission 'report.custom'

    def resolve(scope: nil)
      restrict(::CustomReport.visible_to(context.current_user), scope).reorder(name: :asc)
    end

    private

    # Sempre a partir de visible_to: o recorte estreita a lista, nunca amplia.
    def restrict(reports, scope)
      user = context.current_user

      case scope
      when 'group'
        reports.joins(:groups).where(groups: { id: ::CustomReport.visible_group_ids(user) })
      when 'personal'
        # "Visão pessoal" é o que o próprio usuário criou. Um relatório que outra
        # pessoa compartilhou com ele aparece em Todos, não aqui.
        reports.where(created_by_id: user.id)
      else
        reports
      end
    end
  end
end
