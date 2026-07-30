# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: relatório personalizado.

module Gql::Types::CustomReport
  class SummaryRowType < Gql::Types::BaseObject
    description 'One group of a custom report summary'

    # Chaves variáveis (dependem dos atributos de agrupamento e das funções
    # escolhidas), por isso JSON e não um tipo fixo — mesma abordagem das linhas
    # do relatório.
    #
    # hash_key é obrigatório em `values`: o objeto é um Hash, e `Hash#values`
    # existe, então sem a chave explícita o campo devolveria os valores do próprio
    # Hash em vez de object[:values]. Ver a nota em ResultType.
    # rubocop:disable GraphQL/UnnecessaryFieldAlias
    field :groups, GraphQL::Types::JSON, null: false, hash_key: :groups,
          description: 'Group values keyed by attribute name'
    field :values, GraphQL::Types::JSON, null: false, hash_key: :values,
          description: 'Aggregated values keyed by aggregation name'
    # rubocop:enable GraphQL/UnnecessaryFieldAlias
  end
end
