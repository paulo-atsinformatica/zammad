# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: relatório personalizado.

module Gql::Types
  class CustomReportType < Gql::Types::BaseObject
    description 'A saved custom report definition'

    # global_id_field, e não `field :id, ID`: as consultas e a mutation resolvem o
    # relatório com Gql::ZammadSchema.verified_object_from_id, que só entende o
    # ID global. Com o id cru a tela mandava "7" de volta e nada era encontrado.
    global_id_field :id

    field :name, String, null: false
    field :object, String, null: false, description: 'Object the rows represent'
    field :active, Boolean, null: false
  end
end
