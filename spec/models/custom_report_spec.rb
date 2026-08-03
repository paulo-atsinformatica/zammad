# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: relatório personalizado.

require 'rails_helper'

RSpec.describe CustomReport do
  # let! nos grupos: o cenário "todos os grupos escolhidos" captura Group.all no
  # momento em que o relatório é criado, e um `let` só criaria o segundo grupo ao
  # avaliar a expectativa — depois disso.
  let!(:group)       { create(:group) }
  let!(:other_group) { create(:group) }

  let(:owner)    { create(:agent, groups: [group]) }
  let(:member)   { create(:agent, groups: [group]) }
  let(:outsider) { create(:agent, groups: [other_group]) }

  # Compartilhamento no modelo da Visão Geral: grupos e/ou usuários escolhidos.
  # Não existe "nível de visibilidade" — quem criou sempre vê o próprio, e
  # "pessoal" é um relatório sem grupo nem usuário adicional.
  describe '#visible_to?' do
    context 'with a report shared with nobody' do
      let(:report) { create(:custom_report, created_by_id: owner.id) }

      it 'is visible to its author' do
        expect(report).to be_visible_to(owner)
      end

      it 'is not visible to anybody else' do
        expect(report).not_to be_visible_to(member)
      end
    end

    context 'with a report shared with a group' do
      let(:report) { create(:custom_report, groups: [group], created_by_id: owner.id) }

      it 'is visible to a member of the chosen group' do
        expect(report).to be_visible_to(member)
      end

      it 'is not visible to someone without access to any chosen group' do
        expect(report).not_to be_visible_to(outsider)
      end

      # É assim que se obtém "visível para todos": escolhendo todos os grupos.
      context 'when every group is chosen' do
        let(:report) { create(:custom_report, groups: Group.all.to_a, created_by_id: owner.id) }

        it 'is visible to everyone with group access' do
          expect(report).to be_visible_to(outsider)
        end
      end
    end

    # Grupos e usuários se somam, não se cruzam: compartilhar com uma pessoa de
    # fora dos grupos tem de funcionar.
    context 'with a report shared directly with a user' do
      let(:report) { create(:custom_report, users: [outsider], created_by_id: owner.id) }

      it 'is visible to that user even without group access' do
        expect(report).to be_visible_to(outsider)
      end

      it 'stays hidden from someone not on either list' do
        expect(report).not_to be_visible_to(member)
      end
    end
  end

  describe '.visible_to' do
    let!(:mine)    { create(:custom_report, created_by_id: member.id) }
    let!(:shared)  { create(:custom_report, groups: [group], created_by_id: owner.id) }
    let!(:direct)  { create(:custom_report, users: [member], created_by_id: owner.id) }
    let!(:hidden)  { create(:custom_report, created_by_id: owner.id) }

    it 'lists my own reports' do
      expect(described_class.visible_to(member)).to include(mine)
    end

    it 'lists the reports shared with my groups' do
      expect(described_class.visible_to(member)).to include(shared)
    end

    it 'lists the reports shared directly with me' do
      expect(described_class.visible_to(member)).to include(direct)
    end

    it 'hides the reports of other people that were not shared' do
      expect(described_class.visible_to(member)).not_to include(hidden)
    end

    it 'hides inactive reports' do
      inactive = create(:custom_report, groups: [group], created_by_id: owner.id, active: false)

      expect(described_class.visible_to(member)).not_to include(inactive)
    end
  end

  # Compartilhar dá leitura, nunca edição.
  describe '#editable_by?' do
    let(:report) { create(:custom_report, groups: [group], created_by_id: owner.id) }

    it 'allows the author' do
      expect(report).to be_editable_by(owner)
    end

    it 'refuses someone who only sees it through a group' do
      expect(report).not_to be_editable_by(member)
    end

    it 'allows an admin' do
      expect(report).to be_editable_by(create(:admin))
    end
  end
end
