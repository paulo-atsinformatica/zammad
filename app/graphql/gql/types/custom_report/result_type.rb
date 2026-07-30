# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: relatório personalizado.

module Gql::Types::CustomReport
  class ResultType < Gql::Types::BaseObject
    description 'A page of results of a custom report'

    field :columns, [Gql::Types::CustomReport::ColumnType, { null: false }], null:        false,
                                                                             description: 'Columns to render, in order'
    field :enabled_filters, [Gql::Types::CustomReport::FilterType, { null: false }], null:        false,
                                                                                     description: 'Attributes the viewer may filter by, with the control to render'
    field :rows, [Gql::Types::CustomReport::RowType, { null: false }], null:        false,
                                                                       description: 'Rows of the requested page'

    field :total_count, Integer, null:        false,
                                 description: 'Total number of matching records'
    field :page, Integer, null:        false,
                          description: 'Current page number'
    field :per_page, Integer, null:        false,
                              description: 'Page size actually applied, after the server side cap'
    field :total_pages, Integer, null:        false,
                                 description: 'Number of pages available'
  end
end
