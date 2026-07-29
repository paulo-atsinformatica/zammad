# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: relatório personalizado.

module Gql::Types
  class CustomReportType < Gql::Types::BaseObject
    description 'A saved custom report definition'

    field :id, GraphQL::Types::ID, null: false
    field :name, String, null: false
    field :object, String, null: false, description: 'Object the rows represent'

    # Controla quem vê o MODELO. O escopo dos dados é sempre recalculado a partir
    # das permissões de quem visualiza (ver CustomReport::Query), então isto não
    # amplia acesso.
    field :visibility, String, null: false, description: 'Who the saved definition is shared with'

    field :active, Boolean, null: false
  end
end
