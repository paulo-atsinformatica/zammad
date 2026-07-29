# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: relatório personalizado.

module Gql::Types::CustomReport
  class ResultType < Gql::Types::BaseObject
    description 'A page of results of a custom report'

    field :columns, [Gql::Types::CustomReport::ColumnType, { null: false }], null: false, hash_key: :columns,
          description: 'Columns to render, in order'
    field :enabled_filters, [Gql::Types::CustomReport::ColumnType, { null: false }], null: false, hash_key: :enabled_filters,
          description: 'Attributes the viewer may filter by'
    field :rows, [Gql::Types::CustomReport::RowType, { null: false }], null: false, hash_key: :rows,
          description: 'Rows of the requested page'

    field :total_count, Integer, null: false, hash_key: :total_count,
          description: 'Total number of matching records'
    field :page, Integer, null: false, hash_key: :page,
          description: 'Current page number'
    field :per_page, Integer, null: false, hash_key: :per_page,
          description: 'Page size actually applied, after the server side cap'
    field :total_pages, Integer, null: false, hash_key: :total_pages,
          description: 'Number of pages available'
  end
end
