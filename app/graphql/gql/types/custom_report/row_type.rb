# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: relatório personalizado.

module Gql::Types::CustomReport
  class RowType < Gql::Types::BaseObject
    description 'A row of a custom report result'

    # hash_key é obrigatório em `values`: o objeto é um Hash e `Hash#values`
    # existe, então sem a chave explícita o campo devolveria os valores do próprio
    # Hash. O disable evita que um `rubocop -a` remova e reintroduza o bug.
    # Ver a nota em ResultType.
    # rubocop:disable GraphQL/UnnecessaryFieldAlias
    field :id, ID, null: false, hash_key: :id,
          description: 'ID of the underlying record, so the grid can link to it'

    # As colunas são escolhidas por relatório, então o conjunto de chaves varia
    # e não cabe num tipo fixo do GraphQL. JSON é o caminho que o próprio Zammad
    # usa para dados de forma dinâmica (ver Gql::Queries::FormUpdater).
    field :values, GraphQL::Types::JSON, null: false, hash_key: :values,
          description: 'Formatted values keyed by attribute name'

    # Vem por linha porque o atributo de agrupamento não precisa estar entre as
    # colunas escolhidas — o grid não teria de onde deduzi-lo.
    field :group_value, String, hash_key:    :group_value,
                                description: 'Label of the section this row belongs to, nil when the report has no grouping'
    # rubocop:enable GraphQL/UnnecessaryFieldAlias
  end
end
