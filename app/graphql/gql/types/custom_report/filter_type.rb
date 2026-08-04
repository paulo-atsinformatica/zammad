# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: relatório personalizado.

module Gql::Types::CustomReport
  class FilterType < Gql::Types::BaseObject
    description 'A filter the viewer of a custom report may fill in'

    # hash_key é obrigatório aqui, apesar do que diz GraphQL/UnnecessaryFieldAlias:
    # o objeto deste tipo é um Hash (CustomReport::FilterDefinition#to_h) e sem a
    # chave explícita a resolução devolve nil, derrubando a consulta inteira com
    # "Cannot return null for non-nullable field CustomReportFilter.display".
    # Coberto por spec em spec/graphql/gql/queries/custom_report/results_spec.rb.
    # rubocop:disable GraphQL/UnnecessaryFieldAlias
    field :name, String, null: false, hash_key: :name,
          description: 'Attribute name to filter by'
    field :display, String, null: false, hash_key: :display,
          description: 'Translated label for the field'

    # Diz à tela que controle renderizar. Sem isto tudo cai num input de texto,
    # o que é inútil para estado, grupo ou data.
    field :type, String, null: false, hash_key: :type,
          description: 'select, date, boolean or text'
    # rubocop:enable GraphQL/UnnecessaryFieldAlias

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
