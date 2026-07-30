# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: relatório personalizado.

module Gql::Types::CustomReport
  class FilterType < Gql::Types::BaseObject
    description 'A filter the viewer of a custom report may fill in'

    field :name, String, null:        false,
                         description: 'Attribute name to filter by'
    field :display, String, null:        false,
                            description: 'Translated label for the field'

    # Diz à tela que controle renderizar. Sem isto tudo cai num input de texto,
    # o que é inútil para estado, grupo ou data.
    field :type, String, null:        false,
                         description: 'select, date, boolean or text'

    field :options, [Gql::Types::CustomReport::FilterOptionType, { null: false }], null:        false,
                                                                                   description: 'Selectable values, empty unless type is select'

    def options
      # CustomReport::FilterDefinition só inclui a chave para 'select'; aqui vira
      # lista vazia, para o campo ser non-null e a tela não tratar nil.
      Array.wrap(object[:options]).map do |option|
        { value: option[:value].to_s, label: option[:label] }
      end
    end
  end
end
