# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: relatório personalizado.

module Gql::Types::CustomReport
  class ColumnType < Gql::Types::BaseObject
    description 'A column of a custom report result'

    # hash_key é obrigatório em `display`: o objeto é um Hash, e Hash responde a
    # `display` (Kernel#display, que imprime e devolve nil). Sem a chave explícita
    # o campo vem nulo e derruba a consulta inteira. O disable existe para um
    # `rubocop -a` não remover o hash_key e reintroduzir o bug — foi exatamente
    # assim que ele entrou. Ver a nota em ResultType.
    # rubocop:disable GraphQL/UnnecessaryFieldAlias
    field :name, String, null: false, hash_key: :name,
          description: 'Attribute name, used as the key inside a row'
    field :display, String, null: false, hash_key: :display,
          description: 'Translated label for the column header'
    # rubocop:enable GraphQL/UnnecessaryFieldAlias
  end
end
