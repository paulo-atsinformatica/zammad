# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: relatório personalizado.

require 'rails_helper'

RSpec.describe CustomReport::FilterDefinition do
  subject(:definition) do
    described_class.new(name: name, display: 'Rótulo', target_class: Ticket, user: user)
  end

  let(:user) { create(:agent, groups: [group]) }

  # let! e não let: no contexto do admin o usuário não referencia o grupo, e um
  # `let` só seria criado ao avaliar a expectativa — depois de options já ter
  # consultado o banco.
  let!(:group) { create(:group) }

  describe '#type' do
    context 'with a reference relation' do
      let(:name) { 'state_id' }

      it { expect(definition.type).to eq('select') }

      it 'lists the states as options' do
        expect(definition.options.pluck(:label)).to include(Ticket::State.first.name)
      end
    end

    context 'with a date column' do
      let(:name) { 'created_at' }

      it { expect(definition.type).to eq('date') }
      it { expect(definition.to_h).not_to have_key(:options) }
    end

    context 'with a plain string column' do
      let(:name) { 'title' }

      it { expect(definition.type).to eq('text') }
    end

    # User e Organization ficam de fora de ENUMERABLE_RELATIONS de propósito:
    # despejar a base inteira na tela seria problema de volume e de privacidade.
    context 'with a relation to a large table' do
      let(:name) { 'customer_id' }

      it 'falls back to text instead of listing every record' do
        expect(definition.type).to eq('text')
      end
    end
  end

  describe 'group options' do
    let(:name)         { 'group_id' }
    let!(:other_group) { create(:group) }

    it 'offers only the groups the user may read' do
      expect(definition.options.pluck(:label)).to include(group.name)
    end

    it 'hides groups the user has no access to' do
      expect(definition.options.pluck(:label)).not_to include(other_group.name)
    end

    context 'with an admin' do
      let(:user) { create(:admin) }

      it 'offers every group' do
        expect(definition.options.pluck(:label)).to include(group.name, other_group.name)
      end
    end
  end

  # display é non-null no GraphQL: um rótulo vazio derrubaria a consulta inteira
  # da tela de visualização, não só o próprio filtro.
  describe 'display fallback' do
    subject(:definition) do
      described_class.new(name: 'state_id', display: display, target_class: Ticket, user: user)
    end

    context 'with a blank display' do
      let(:display) { '' }

      it 'falls back to a humanized attribute name' do
        expect(definition.display).to eq('State')
      end
    end

    context 'with a nil display' do
      let(:display) { nil }

      it 'still returns a label' do
        expect(definition.display).to be_present
      end
    end
  end

  describe '#permits?' do
    context 'with a select filter' do
      let(:name) { 'state_id' }

      it { expect(definition.permits?('is')).to be(true) }

      # 'contains' num campo de id não faz sentido e mudaria o significado do
      # filtro.
      it { expect(definition.permits?('contains')).to be(false) }
    end

    context 'with a text filter' do
      let(:name) { 'title' }

      it { expect(definition.permits?('contains')).to be(true) }
      it { expect(definition.permits?('after (absolute)')).to be(false) }
    end

    it 'never permits an operator the selector does not know' do
      expect(described_class::OPERATORS_BY_TYPE.values.flatten.uniq - Selector::Sql::VALID_OPERATORS)
        .to be_empty
    end

    context 'with an unknown operator' do
      let(:name) { 'title' }

      it { expect(definition.permits?('drop table')).to be(false) }
    end
  end
end
