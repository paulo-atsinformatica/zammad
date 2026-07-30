# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: relatório personalizado.

module Gql::Types::CustomReport
  class FilterOptionType < Gql::Types::BaseObject
    description 'One selectable value of a custom report filter'

    # Ver a nota em FilterType: o objeto é um Hash, então hash_key não é
    # redundante — sem ele a resolução devolve nil.
    # rubocop:disable GraphQL/UnnecessaryFieldAlias
    field :value, String, null: false, hash_key: :value,
          description: 'Value to send back when filtering'
    field :label, String, null: false, hash_key: :label,
          description: 'Translated label to show'
    # rubocop:enable GraphQL/UnnecessaryFieldAlias
  end
end
