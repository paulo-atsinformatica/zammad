# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: relatório personalizado.

module Gql::Types::CustomReport
  class SummaryType < Gql::Types::BaseObject
    description 'Grouped totals of a custom report'

    # hash_key explícito em todo o tipo: o objeto é um Hash e um campo cujo nome
    # coincida com um método de Hash resolveria para o método. Ver a nota em
    # ResultType.
    # rubocop:disable GraphQL/UnnecessaryFieldAlias
    field :group_by, [Gql::Types::CustomReport::ColumnType, { null: false }], null: false, hash_key: :group_by,
          description: 'Attributes the rows are grouped by, in order'
    field :aggregations, [Gql::Types::CustomReport::ColumnType, { null: false }], null: false, hash_key: :aggregations,
          description: 'Calculated totals, in order'
    field :rows, [Gql::Types::CustomReport::SummaryRowType, { null: false }], null: false, hash_key: :rows,
          description: 'One entry per group combination'
    field :totals, GraphQL::Types::JSON, null: false, hash_key: :totals,
          description: 'Grand total, keyed by aggregation name'
    # rubocop:enable GraphQL/UnnecessaryFieldAlias
  end
end
