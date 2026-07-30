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

  # Só dois níveis: 'personal' e 'group' ("Geral"). Não existe nível global —
  # para valer para todos, escolhem-se todos os grupos.
  describe 'visibility levels' do
    it 'accepts personal and group' do
      expect(described_class::VISIBILITIES).to eq(%w[personal group])
    end

    it 'rejects the removed global level' do
      report = build(:custom_report, visibility: 'global')

      expect(report).not_to be_valid
    end
  end

  describe '#visible_to?' do
    context 'with a personal report' do
      let(:report) { create(:custom_report, visibility: 'personal', created_by_id: owner.id) }

      it 'is visible to its author' do
        expect(report).to be_visible_to(owner)
      end

      it 'is not visible to anybody else' do
        expect(report).not_to be_visible_to(member)
      end
    end

    context 'with a general report' do
      let(:report) do
        create(:custom_report, visibility: 'group', groups: [group], created_by_id: owner.id)
      end

      it 'is visible to a member of the chosen group' do
        expect(report).to be_visible_to(member)
      end

      it 'is not visible to someone without access to any chosen group' do
        expect(report).not_to be_visible_to(outsider)
      end

      # É assim que se obtém "visível para todos": escolhendo todos os grupos.
      context 'when every group is chosen' do
        let(:report) do
          create(:custom_report, visibility: 'group', groups: Group.all.to_a, created_by_id: owner.id)
        end

        it 'is visible to everyone with group access' do
          expect(report).to be_visible_to(outsider)
        end
      end
    end
  end

  describe '.visible_to' do
    let!(:mine)    { create(:custom_report, visibility: 'personal', created_by_id: member.id) }
    let!(:general) { create(:custom_report, visibility: 'group', groups: [group], created_by_id: owner.id) }
    let!(:hidden)  { create(:custom_report, visibility: 'personal', created_by_id: owner.id) }

    it 'lists my own reports' do
      expect(described_class.visible_to(member)).to include(mine)
    end

    it 'lists the general reports of my groups' do
      expect(described_class.visible_to(member)).to include(general)
    end

    it 'hides the personal reports of other people' do
      expect(described_class.visible_to(member)).not_to include(hidden)
    end
  end

  describe 'group requirement' do
    it 'requires a group for a general report' do
      expect(build(:custom_report, visibility: 'group', groups: [])).not_to be_valid
    end

    it 'does not require one for a personal report' do
      expect(build(:custom_report, visibility: 'personal', groups: [])).to be_valid
    end
  end
end
