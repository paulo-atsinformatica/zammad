# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: relatório personalizado.

require 'rails_helper'

RSpec.describe Gql::Queries::CustomReport::List, type: :graphql do
  let(:group)   { create(:group) }
  let!(:report) { create(:custom_report_shared, name: 'Tickets abertos', groups: [group]) }

  let(:query) do
    <<~QUERY
      query customReportList($scope: String) {
        customReportList(scope: $scope) {
          id
          name
          object
          active
        }
      }
    QUERY
  end

  # O papel Agent recebe report.custom no seed, então nada a conceder aqui.
  context 'with an agent allowed to use custom reports', authenticated_as: :agent do
    let(:agent) { create(:agent, groups: [group]) }

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

      expect(Gql::ZammadSchema.verified_object_from_id(id, type: CustomReport)).to eq(report)
    end

    # "Visão pessoal" é o que o próprio usuário criou.
    it 'restricts to my own reports when asked' do
      create(:custom_report, name: 'Somente meu', created_by_id: agent.id)

      gql.execute(query, variables: { scope: 'personal' })

      expect(gql.result.data.pluck('name')).to eq(['Somente meu'])
    end

    it 'restricts to the reports shared with my groups when asked' do
      create(:custom_report, name: 'Somente meu', created_by_id: agent.id)

      gql.execute(query, variables: { scope: 'group' })

      expect(gql.result.data.pluck('name')).to eq(['Tickets abertos'])
    end

    # O recorte estreita a lista, nunca amplia: um relatório de outra pessoa,
    # não compartilhado, não pode aparecer em nenhum escopo.
    it 'never widens beyond what the user may see' do
      create(:custom_report, name: 'De outro', created_by_id: create(:agent).id)

      gql.execute(query)

      expect(gql.result.data.pluck('name')).not_to include('De outro')
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
