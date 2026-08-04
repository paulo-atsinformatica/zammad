# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: relatório personalizado.

module Gql::Queries
  class CustomReport::Results < BaseQuery

    description 'A page of results of a custom report'

    argument :custom_report_id, GraphQL::Types::ID, description: 'Custom report to run'
    argument :filters, GraphQL::Types::JSON, required: false,
             description: 'Filters filled in by the viewer, keyed by attribute name. Only attributes the report enabled are applied.'
    argument :page, Integer, required: false, description: 'Page number, starting at 1'
    argument :per_page, Integer, required: false, description: 'Page size. Capped server side.'
    argument :order_by, String, required: false, description: 'Attribute to sort by'
    argument :order_direction, String, required: false, description: 'asc or desc'

    type Gql::Types::CustomReport::ResultType, null: false

    requires_permission 'report.custom'

    def resolve(custom_report_id:, filters: nil, page: 1, per_page: nil, order_by: nil, order_direction: 'asc')
      report = fetch_report(custom_report_id)

      ::CustomReport::Result.new(
        report:          report,
        user:            context.current_user,
        filters:         filters,
        page:            page,
        per_page:        per_page,
        order_by:        order_by,
        order_direction: order_direction,
      ).call
    end

    private

    # Não usa `loads:` porque a visibilidade do modelo é regra do próprio
    # CustomReport. Um relatório que o usuário não enxerga responde como
    # inexistente, para não revelar que existe.
    def fetch_report(custom_report_id)
      report = Gql::ZammadSchema.verified_object_from_id(custom_report_id, type: ::CustomReport)
      raise ActiveRecord::RecordNotFound, "Could not find CustomReport #{custom_report_id}" if !report.visible_to?(context.current_user)

      report
    end
  end
end
