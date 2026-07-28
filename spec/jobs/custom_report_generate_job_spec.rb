# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: relatório personalizado.

require 'rails_helper'

RSpec.describe CustomReportGenerateJob do
  let(:group_allowed) { create(:group) }
  let(:group_denied)  { create(:group) }
  let(:agent)         { create(:agent, groups: [group_allowed]) }

  let!(:allowed_ticket) { create(:ticket, group: group_allowed, title: 'visivel') }
  let!(:denied_ticket)  { create(:ticket, group: group_denied, title: 'invisivel') }

  let(:report) do
    create(:custom_report,
           object:        'Ticket',
           visibility:    'global',
           condition:     {},
           columns:       %w[number title state_id group_id],
           created_by_id: agent.id,
           updated_by_id: agent.id)
  end

  let(:run) do
    create(:custom_report_run,
           custom_report: report,
           format:        'csv',
           filename:      'relatorio.csv',
           created_by_id: agent.id,
           updated_by_id: agent.id)
  end

  # O arquivo fica sob storage/, fora do controle do DatabaseCleaner.
  after { run.destroy }

  def csv_content
    File.read(run.reload.file_path)
  end

  context 'when generating succeeds' do
    before { described_class.perform_now(run: run) }

    it 'marks the run as succeeded' do
      expect(run.reload).to have_attributes(status: 'succeeded', error: nil)
    end

    it 'counts every exported row' do
      expect(run.reload).to have_attributes(total_rows: 1, processed_rows: 1)
    end

    it 'makes the run downloadable and sets an expiry' do
      expect(run.reload).to have_attributes(expires_at: be_present)
        .and(satisfy(&:downloadable?))
    end

    it 'writes a header using the field labels instead of column names' do
      expect(csv_content.lines.first).to include('Title', 'State')
    end

    # Relações precisam sair pelo nome: os modelos de relação do Zammad não
    # sobrescrevem to_s, então um descuido exporta #<Ticket::State:0x...>.
    it 'exports related records by name' do
      expect(csv_content).to include(group_allowed.name).and(include('new'))
    end

    it 'exports the tickets the user may read' do
      expect(csv_content).to include('visivel')
    end

    # A verificação que importa: o relatório é global, mas os dados continuam
    # limitados às permissões de quem gerou.
    it 'does not leak tickets from groups the user cannot read' do
      expect(csv_content).not_to include('invisivel')
    end
  end

  context 'when the result is above the configured row limit' do
    before do
      Setting.set('custom_report_max_rows', 0)
      described_class.perform_now(run: run)
    end

    it 'fails the run instead of generating a huge file' do
      expect(run.reload).to have_attributes(status: 'failed', error: include('above the limit'))
    end
  end
end
