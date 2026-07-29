# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: relatório personalizado.

require 'rails_helper'

RSpec.describe Gql::Queries::CustomReport::List, type: :graphql do
  let!(:report) { create(:custom_report, name: 'Tickets abertos', visibility: 'global') }

  let(:query) do
    <<~QUERY
      query customReportList($visibility: String) {
        customReportList(visibility: $visibility) {
          id
          name
          object
          visibility
          active
        }
      }
    QUERY
  end

  # O papel Agent recebe report.custom no seed, então nada a conceder aqui.
  context 'with an agent allowed to use custom reports', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    it 'lists the visible reports' do
      gql.execute(query)

      expect(gql.result.data.pluck('name')).to include('Tickets abertos')
    end

    # A tela usa o id devolvido aqui como argumento de customReportResults e
    # customReportGenerate, que resolvem por ID global. Se este campo voltar a
    # expor o id cru, a tela para de carregar dados.
    it 'returns an id the other operations can resolve' do
      gql.execute(query)

      id = gql.result.data.first['id']

      expect(Gql::ZammadSchema.verified_object_from_id(id, type: ::CustomReport)).to eq(report)
    end

    it 'restricts to a visibility level when asked' do
      create(:custom_report, name: 'Somente meu', visibility: 'personal', created_by_id: agent.id)

      gql.execute(query, variables: { visibility: 'personal' })

      expect(gql.result.data.pluck('name')).to eq(['Somente meu'])
    end
  end

  context 'with a user lacking the custom report permission', authenticated_as: :customer do
    let(:customer) { create(:customer) }

    it 'is forbidden' do
      gql.execute(query)

      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end
end
