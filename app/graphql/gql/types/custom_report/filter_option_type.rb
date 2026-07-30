# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: relatório personalizado.

module Gql::Types::CustomReport
  class FilterOptionType < Gql::Types::BaseObject
    description 'One selectable value of a custom report filter'

    field :value, String, null:        false,
                          description: 'Value to send back when filtering'
    field :label, String, null:        false,
                          description: 'Translated label to show'
  end
end
