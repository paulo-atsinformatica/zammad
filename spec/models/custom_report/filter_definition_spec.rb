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
    # Em vez de lista, esses viram campo de busca — texto livre não serve, porque
    # a coluna comparada é o *_id.
    context 'with a relation to a large table' do
      it 'offers an agent search for the owner' do
        expect(described_class.new(name: 'owner_id', display: 'owner_id', target_class: Ticket, user: user).type)
          .to eq('agent')
      end

      it 'offers a user search for the customer' do
        expect(described_class.new(name: 'customer_id', display: 'customer_id', target_class: Ticket, user: user).type)
          .to eq('customer')
      end

      it 'offers an organization search for the organization' do
        expect(described_class.new(name: 'organization_id', display: 'organization_id', target_class: Ticket, user: user).type)
          .to eq('organization')
      end
    end

    # Regressão: com o tipo 'text' o operador 'contains' era aceito e virava
    # ILIKE sobre uma coluna integer, o que o Postgres recusa com
    # "operator does not exist: integer ~~* unknown".
    context 'with a numeric column' do
      let(:name) { 'article_count' }

      it { expect(definition.type).to eq('number') }

      it 'does not accept a text operator' do
        expect(definition.permits?('contains')).to be(false)
      end
    end

    it 'never resolves a numeric column to a type that accepts contains' do
      numeric = Ticket.columns_hash.select { |_, column| %i[integer bigint decimal float].include?(column.type) }.keys

      offenders = numeric.select do |attribute|
        described_class.new(name: attribute, display: attribute, target_class: Ticket, user: user).permits?('contains')
      end

      expect(offenders).to be_empty
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

    # Data é sempre período na tela: um filtro de dia único é a mesma data nos
    # dois campos, e não um operador diferente.
    context 'with a date filter' do
      let(:name) { 'created_at' }

      it { expect(definition.permits?('in range')).to be(true) }
      it { expect(definition.permits?('contains')).to be(false) }
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
