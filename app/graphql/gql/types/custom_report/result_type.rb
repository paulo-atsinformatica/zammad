# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: relatório personalizado.

module Gql::Types::CustomReport
  class ResultType < Gql::Types::BaseObject
    description 'A page of results of a custom report'

    # hash_key em todos os campos, apesar do que diz GraphQL/UnnecessaryFieldAlias.
    # O objeto deste tipo é um Hash (CustomReport::Result#call), e o graphql chama
    # o método antes de olhar a chave: `Hash` responde a `display`, `values` e
    # `count` (Kernel#display, Hash#values, Hash#count), então um campo com esses
    # nomes resolveria para o retorno do método — nil, no caso de `display` — em
    # vez do valor. Sem hash_key a consulta inteira cai com "Cannot return null
    # for non-nullable field". Manter explícito em todo o tipo evita que um campo
    # novo caia na mesma armadilha.
    # rubocop:disable GraphQL/UnnecessaryFieldAlias
    field :columns, [Gql::Types::CustomReport::ColumnType, { null: false }], null: false, hash_key: :columns,
          description: 'Columns to render, in order'
    field :enabled_filters, [Gql::Types::CustomReport::FilterType, { null: false }], null: false, hash_key: :enabled_filters,
          description: 'Attributes the viewer may filter by, with the control to render'
    field :rows, [Gql::Types::CustomReport::RowType, { null: false }], null: false, hash_key: :rows,
          description: 'Rows of the requested page'

    # Nulo quando o relatório não define agrupamento, e o grid sai como lista
    # simples.
    field :grouping, Gql::Types::CustomReport::ColumnType, hash_key:    :grouping,
                                                           description: 'Attribute the grid is broken into sections by, nil when there is none'
    field :group_counts, [Gql::Types::CustomReport::GroupCountType, { null: false }], null: false, hash_key: :group_counts,
          description: 'Record count of each group, across the whole result and not just this page'

    # Nulo quando o relatório não define totalizadores, para a tela não desenhar a
    # seção.
    field :summary, Gql::Types::CustomReport::SummaryType, hash_key:    :summary,
                                                           description: 'Grouped totals, nil when the report defines none'

    field :total_count, Integer, null: false, hash_key: :total_count,
          description: 'Total number of matching records'
    field :page, Integer, null: false, hash_key: :page,
          description: 'Current page number'
    field :per_page, Integer, null: false, hash_key: :per_page,
          description: 'Page size actually applied, after the server side cap'
    field :total_pages, Integer, null: false, hash_key: :total_pages,
          description: 'Number of pages available'
    # rubocop:enable GraphQL/UnnecessaryFieldAlias
  end
end
