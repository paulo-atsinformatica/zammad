# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: relatório personalizado.

module Gql::Types::CustomReport
  class ColumnType < Gql::Types::BaseObject
    description 'A column of a custom report result'

    field :name, String, null: false, hash_key: :name,
          description: 'Attribute name, used as the key inside a row'
    field :display, String, null: false, hash_key: :display,
          description: 'Translated label for the column header'
  end
end
