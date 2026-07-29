# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: relatório personalizado.

module Gql::Queries
  class CustomReport::Runs < BaseQuery

    description 'Report generations started by the current user'

    argument :limit, Integer, required: false, description: 'How many runs to return, newest first'

    type [Gql::Types::CustomReportRunType, { null: false }], null: false

    requires_permission 'report.custom'

    # Restrito a for_user: o arquivo gerado já contém dados materializados sob as
    # permissões de quem o gerou, então não pode ser listado nem baixado por
    # outra pessoa, mesmo que ambas enxerguem o mesmo modelo.
    def resolve(limit: 20)
      ::CustomReportRun
        .for_user(context.current_user)
        .recent
        .limit([limit, 100].min)
    end
  end
end
