# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: relatório personalizado.

module Gql::Types::CustomReport
  class GroupCountType < Gql::Types::BaseObject
    description 'How many records a group of the report holds'

    # hash_key em todos os campos: o objeto é um Hash e `count` existe em Hash,
    # então sem a chave o campo resolveria para Hash#count. Mesma armadilha
    # documentada em CustomReport::ResultType.
    # rubocop:disable GraphQL/UnnecessaryFieldAlias
    field :value, String, null: false, hash_key: :value,
          description: 'Label of the group, already resolved for relations'
    field :count, Integer, null: false, hash_key: :count,
          description: 'Number of records in the group, across the whole result'
    # rubocop:enable GraphQL/UnnecessaryFieldAlias
  end
end
