# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: relatório personalizado.

require 'rails_helper'

RSpec.describe CustomReport::Result do
  subject(:result) { described_class.new(report:, user:, **options).call }

  let(:options) { {} }
  let(:group)   { create(:group) }
  let(:user)    { create(:agent, groups: [group]) }

  let!(:alpha) { create(:ticket, group:, title: 'alpha') }
  let!(:beta)  { create(:ticket, group:, title: 'beta') }

  let(:report) do
    create(:custom_report,
           object:          'Ticket',
           columns:         %w[number title state_id],
           enabled_filters: %w[title],
           condition:       {},
           created_by_id:   user.id,
           updated_by_id:   user.id)
  end

  describe 'column metadata' do
    it 'returns one entry per configured column, in order' do
      expect(result[:columns].pluck(:name)).to eq(%w[number title state_id])
    end

    # O grid monta o cabeçalho a partir disto, então precisa vir o rótulo do
    # campo e não o nome da coluna do banco.
    it 'exposes the field label, not the column name' do
      expect(result[:columns].pluck(:display)).to include('Title', 'State')
    end
  end

  describe 'rows' do
    it 'returns a value for each configured column' do
      expect(result[:rows].first[:values].keys).to eq(%w[number title state_id])
    end

    it 'resolves related records by name instead of id' do
      expect(result[:rows].first[:values]['state_id']).to eq('new')
    end

    it 'includes the record id so the grid can link to it' do
      expect(result[:rows].pluck(:id)).to include(alpha.id, beta.id)
    end
  end

  describe 'pagination' do
    let(:options) { { per_page: 1 } }

    it 'returns only the requested page size' do
      expect(result[:rows].size).to eq(1)
    end

    it 'reports the full count and page total' do
      expect(result).to include(total_count: 2, total_pages: 2, page: 1, per_page: 1)
    end

    it 'returns different records on the next page' do
      first  = described_class.new(report:, user:, per_page: 1, page: 1).call
      second = described_class.new(report:, user:, per_page: 1, page: 2).call

      expect(first[:rows].pluck(:id)).not_to eq(second[:rows].pluck(:id))
    end

    # Sem teto, um per_page enorme vindo da requisição viraria uma consulta
    # capaz de derrubar o servidor.
    it 'caps per_page at the maximum' do
      capped = described_class.new(report:, user:, per_page: 99_999).call

      expect(capped[:per_page]).to eq(CustomReport::Query::MAX_PER_PAGE)
    end
  end

  describe 'runtime filters' do
    it 'applies a filter on an enabled attribute' do
      filtered = described_class.new(report:, user:, filters: { 'title' => { 'operator' => 'is', 'value' => 'alpha' } }).call

      expect(filtered[:rows].pluck(:id)).to contain_exactly(alpha.id)
    end

    # Filtrar por atributo que o autor não expôs precisa ser ignorado, senão a
    # tela poderia recortar o relatório por qualquer campo.
    it 'ignores a filter on an attribute the report did not enable' do
      filtered = described_class.new(report:, user:, filters: { 'number' => { 'operator' => 'is', 'value' => alpha.number } }).call

      expect(filtered[:total_count]).to eq(2)
    end

    it 'lists the enabled filters with their labels' do
      expect(result[:enabled_filters]).to contain_exactly(include(name: 'title', display: 'Title'))
    end
  end

  # O componente de atributos do Zammad (o mesmo da Visão Geral) salva o nome
  # sem o sufixo de relação, então é nesse formato que os valores chegam da
  # interface.
  describe 'attribute names without the relation suffix' do
    let(:report) do
      create(:custom_report,
             object:          'Ticket',
             columns:         %w[number title state],
             enabled_filters: %w[title],
             created_by_id:   user.id,
             updated_by_id:   user.id)
    end

    it 'resolves them to the real column' do
      expect(result[:columns].pluck(:name)).to eq(%w[number title state_id])
    end

    it 'still exports the related record by name' do
      expect(result[:rows].first[:values]['state_id']).to eq('new')
    end

    it 'accepts them as enabled filters' do
      expect(report).to be_valid
    end
  end

  describe 'permissions' do
    let(:other_group)     { create(:group) }
    let!(:hidden_ticket)  { create(:ticket, group: other_group, title: 'hidden') }

    # Mesma garantia da geração de arquivo: a página de resultados também parte
    # do scope de permissão de quem visualiza.
    it 'does not return records outside the reach of the viewer' do
      expect(result[:rows].pluck(:id)).not_to include(hidden_ticket.id)
    end
  end
end
