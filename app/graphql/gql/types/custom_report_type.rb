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

    # resolver_method explícito: `object` é o acessor que o graphql-ruby usa para
    # chegar ao registro sendo resolvido, então um campo com esse nome resolvia
    # para o próprio CustomReport e a consulta devolvia
    # "#<CustomReport:0x00007f...>" em vez de "Ticket". Mesma armadilha que
    # CustomReport::ResultType evita com hash_key.
    field :object, String, null: false, resolver_method: :report_object,
          description: 'Object the rows represent'

    field :active, Boolean, null: false

    # Aqui `object` é o registro (o acessor do graphql-ruby); `.object` nele é a
    # coluna.
    def report_object
      object.object
    end
  end
end
