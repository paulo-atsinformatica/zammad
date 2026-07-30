# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: relatório personalizado.

require 'rails_helper'

RSpec.describe CustomReport::Summary do
  subject(:summary) { described_class.new(report: report, query: query, columns: columns) }

  let(:user)    { create(:agent, groups: [group_a, group_b]) }
  let(:group_a) { create(:group) }
  let(:group_b) { create(:group) }

  let!(:tickets_a) { create_list(:ticket, 2, group: group_a) }
  let!(:ticket_b)  { create(:ticket, group: group_b) }

  let(:query)   { CustomReport::Query.new(report: report, user: user) }
  let(:columns) { CustomReport::Columns.new(report: report, user: user) }

  let(:report) do
    create(:custom_report,
           object:       'Ticket',
           condition:    {},
           group_by:     %w[group],
           aggregations: %w[count])
  end

  it 'counts the records of each group' do
    counts = summary.call[:rows].to_h { |row| [row[:groups]['group_id'], row[:values]['count']] }

    expect(counts).to include(group_a.name => tickets_a.size, group_b.name => 1)
  end

  it 'resolves the group value to its name instead of the id' do
    expect(summary.call[:rows].map { |row| row[:groups]['group_id'] })
      .to include(group_a.name)
  end

  it 'returns a grand total' do
    expect(summary.call[:totals]['count']).to eq(3)
  end

  it 'labels the aggregation' do
    expect(summary.call[:aggregations].pluck(:display)).to eq(['Count'])
  end

  # O resumo é calculado sobre o escopo permitido, igual à listagem: um usuário
  # restrito não pode ver um total que revele registros de outro grupo.
  context 'with an agent restricted to one group' do
    let(:user) { create(:agent, groups: [group_a]) }

    it 'totals only what the user may read' do
      expect(summary.call[:totals]['count']).to eq(tickets_a.size)
    end

    it 'does not list the group the user cannot read' do
      expect(summary.call[:rows].map { |row| row[:groups]['group_id'] })
        .not_to include(group_b.name)
    end
  end

  context 'without any aggregation' do
    let(:report) do
      create(:custom_report, object: 'Ticket', condition: {}, group_by: %w[group], aggregations: [])
    end

    it 'returns nil so the screen skips the section' do
      expect(summary.call).to be_nil
    end
  end

  # Função e atributo entram no SELECT, então tudo que não estiver nas listas
  # fechadas é descartado em vez de chegar ao SQL.
  context 'with an unknown function' do
    let(:report) do
      create(:custom_report, object: 'Ticket', condition: {}, group_by: %w[group],
                             aggregations: ['count', 'DROP TABLE tickets'])
    end

    it 'keeps only the known function' do
      expect(summary.call[:aggregations].pluck(:function)).to eq(%w[count])
    end
  end

  context 'with sum over a non numeric field' do
    let(:report) do
      create(:custom_report, object: 'Ticket', condition: {}, group_by: %w[group],
                             aggregations: %w[sum], aggregation_attributes: %w[title])
    end

    it 'drops the aggregation instead of asking the database to sum text' do
      expect(summary.call).to be_nil
    end
  end

  context 'with sum over a numeric field' do
    let(:report) do
      create(:custom_report, object: 'Ticket', condition: {}, group_by: %w[group],
                             aggregations: %w[sum], aggregation_attributes: %w[priority])
    end

    it 'builds the aggregation' do
      expect(summary.call[:aggregations].pluck(:name)).to eq(%w[sum_priority_id])
    end
  end

  context 'without group_by but with an aggregation' do
    let(:report) do
      create(:custom_report, object: 'Ticket', condition: {}, group_by: [], aggregations: %w[count])
    end

    it 'still returns the grand total' do
      expect(summary.call[:totals]['count']).to eq(3)
    end

    it 'has no group rows' do
      expect(summary.call[:rows]).to be_empty
    end
  end
end
