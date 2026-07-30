# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: relatório personalizado.

require 'rails_helper'

RSpec.describe CustomReport::Query do
  subject(:query) { described_class.new(report: report, user: user) }

  let(:group_a) { create(:group) }
  let(:group_b) { create(:group) }

  let!(:ticket_a) { create(:ticket, group: group_a, title: 'in group a') }
  let!(:ticket_b) { create(:ticket, group: group_b, title: 'in group b') }

  # Sem condição alguma: o resultado é definido apenas pelas permissões, que é
  # exatamente o cenário em que um vazamento apareceria.
  let(:report) do
    create(:custom_report, object: 'Ticket', visibility: 'personal', condition: {})
  end

  describe 'permission intersection' do
    context 'when the user is an agent with access to a single group' do
      let(:user) { create(:agent, groups: [group_a]) }

      it 'returns the tickets of that group' do
        expect(query.relation).to include(ticket_a)
      end

      it 'does not leak tickets of groups the user cannot read' do
        expect(query.relation).not_to include(ticket_b)
      end
    end

    context 'when the user is an agent with access to both groups' do
      let(:user) { create(:agent, groups: [group_a, group_b]) }

      it 'returns tickets of both groups' do
        expect(query.relation).to include(ticket_a, ticket_b)
      end
    end

    # O nível de visibilidade compartilha o MODELO, nunca os dados. Um relatório
    # global aberto por um agente restrito continua restrito.
    context 'when a globally shared report is run by a restricted agent' do
      let(:user) { create(:agent, groups: [group_a]) }

      it 'still applies the permissions of the user generating it' do
        expect(query.relation).to contain_exactly(ticket_a)
      end
    end

    context 'when the user is a customer' do
      let(:user)      { create(:customer) }
      let!(:own)      { create(:ticket, group: group_a, customer: user) }

      it 'returns only their own tickets' do
        expect(query.relation).to contain_exactly(own)
      end
    end
  end

  describe 'conditions' do
    let(:user) { create(:agent, groups: [group_a, group_b]) }
    let(:report) do
      create(:custom_report,
             object:    'Ticket',
             condition: { 'ticket.title' => { operator: 'is', value: 'in group a' } })
    end

    it 'applies the saved condition on top of the permitted scope' do
      expect(query.relation).to contain_exactly(ticket_a)
    end
  end

  # Filtros vindos da tela. O operador chega da requisição e iria direto ao
  # Selector::Sql, então o recorte aqui é de segurança, não de conveniência.
  describe 'runtime filters' do
    subject(:query) { described_class.new(report: report, user: user, filters: filters) }

    let(:user) { create(:agent, groups: [group_a, group_b]) }
    let(:report) do
      create(:custom_report, object: 'Ticket', condition: {}, enabled_filters: %w[title])
    end

    context 'with an enabled attribute and a permitted operator' do
      let(:filters) { { 'title' => { 'operator' => 'contains', 'value' => 'group a' } } }

      it 'applies the filter' do
        expect(query.relation).to contain_exactly(ticket_a)
      end
    end

    context 'with an attribute the report did not enable' do
      let(:filters) { { 'group_id' => { 'operator' => 'is', 'value' => [group_a.id] } } }

      it 'ignores it' do
        expect(query.runtime_filters).to be_empty
      end

      it 'still returns everything the user may read' do
        expect(query.relation).to include(ticket_a, ticket_b)
      end
    end

    context 'with an operator the attribute type does not allow' do
      let(:filters) { { 'title' => { 'operator' => 'after (absolute)', 'value' => '2026-01-01' } } }

      it 'drops the condition instead of passing it to the selector' do
        expect(query.runtime_filters).to be_empty
      end
    end

    context 'with an operator the selector does not know' do
      let(:filters) { { 'title' => { 'operator' => 'nonsense', 'value' => 'x' } } }

      it 'drops the condition' do
        expect(query.runtime_filters).to be_empty
      end

      it 'does not raise when building the relation' do
        expect { query.relation.to_a }.not_to raise_error
      end
    end

    context 'with a blank value' do
      let(:filters) { { 'title' => { 'operator' => 'contains', 'value' => '' } } }

      it 'treats it as no filter' do
        expect(query.runtime_filters).to be_empty
      end
    end
  end

  describe '#exceeds_max_rows?' do
    let(:user) { create(:agent, groups: [group_a, group_b]) }

    it 'is false while below the configured limit' do
      expect(query).not_to be_exceeds_max_rows
    end

    it 'is true once the limit is lower than the result count' do
      Setting.set('custom_report_max_rows', 1)

      expect(query).to be_exceeds_max_rows
    end
  end
end
