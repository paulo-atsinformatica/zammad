# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: relatório personalizado.

require 'rails_helper'

RSpec.describe Gql::Queries::CustomReport::Results, type: :graphql do
  let(:group)    { create(:group) }
  let!(:visible) { create(:ticket, group:, title: 'visivel') }

  let(:report) do
    create(:custom_report,
           object:          'Ticket',
           visibility:      'group',
           groups:          [group],
           columns:         %w[number title state],
           enabled_filters: %w[title],
           created_by_id:   1,
           updated_by_id:   1)
  end

  let(:query) do
    <<~QUERY
      query customReportResults($customReportId: ID!, $page: Int, $perPage: Int) {
        customReportResults(customReportId: $customReportId, page: $page, perPage: $perPage) {
          columns { name display }
          enabledFilters { name display }
          rows { id values }
          totalCount
          page
          perPage
          totalPages
        }
      }
    QUERY
  end

  let(:variables) { { customReportId: Gql::ZammadSchema.id_from_object(report) } }

  before { gql.execute(query, variables:) }

  # O papel Agent recebe report.custom no seed, então nada a conceder aqui.
  context 'with an agent allowed to use custom reports', authenticated_as: :agent do
    let(:agent) { create(:agent, groups: [group]) }

    it 'returns the column metadata with translated labels' do
      expect(gql.result.data['columns'].pluck('display')).to include('Title', 'State')
    end

    # A interface salva "state"; o backend precisa devolver a coluna real.
    it 'resolves the relation suffix so state maps to the real column' do
      expect(gql.result.data['columns'].pluck('name')).to eq(%w[number title state_id])
    end

    # values é JSON porque as colunas variam por relatório; este teste garante
    # que o scalar chega serializado e não como objeto opaco.
    it 'returns row values keyed by attribute name' do
      expect(gql.result.data['rows'].first['values']).to include('title' => 'visivel')
    end

    it 'returns the pagination information' do
      expect(gql.result.data).to include('totalCount' => 1, 'page' => 1, 'totalPages' => 1)
    end

    it 'lists the enabled filters' do
      expect(gql.result.data['enabledFilters']).to contain_exactly('name' => 'title', 'display' => 'Title')
    end
  end

  context 'with a user lacking the custom report permission', authenticated_as: :customer do
    let(:customer) { create(:customer) }

    it 'is forbidden' do
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end

  # Um relatório que o usuário não enxerga responde como inexistente, para não
  # revelar que existe.
  context 'with a report the user cannot see', authenticated_as: :agent do
    let(:agent) { create(:agent, groups: [group]) }

    let(:report) do
      create(:custom_report,
             object:        'Ticket',
             visibility:    'personal',
             created_by_id: create(:agent).id,
             updated_by_id: 1)
    end

    it 'reports it as not found' do
      expect(gql.result.error_type).to eq(ActiveRecord::RecordNotFound)
    end
  end
end
