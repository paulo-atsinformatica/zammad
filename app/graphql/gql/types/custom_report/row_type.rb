# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: relatório personalizado.

module Gql::Types::CustomReport
  class RowType < Gql::Types::BaseObject
    description 'A row of a custom report result'

    field :id, ID, null: false, hash_key: :id,
          description: 'ID of the underlying record, so the grid can link to it'

    # As colunas são escolhidas por relatório, então o conjunto de chaves varia
    # e não cabe num tipo fixo do GraphQL. JSON é o caminho que o próprio Zammad
    # usa para dados de forma dinâmica (ver Gql::Queries::FormUpdater).
    field :values, GraphQL::Types::JSON, null: false, hash_key: :values,
          description: 'Formatted values keyed by attribute name'
  end
end
