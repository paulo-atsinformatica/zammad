# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: relatório personalizado.

require 'rails_helper'

RSpec.describe Gql::Queries::CustomReport::Runs, type: :graphql do
  let(:report) { create(:custom_report, visibility: 'global') }

  let(:query) do
    <<~QUERY
      query customReportRuns($limit: Int) {
        customReportRuns(limit: $limit) {
          id
          status
          progressPercent
          downloadable
          downloadPath
          customReport { name }
        }
      }
    QUERY
  end

  # O papel Agent recebe report.custom no seed, então nada a conceder aqui.
  context 'with an agent allowed to use custom reports', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    it 'lists only the runs of the requesting user' do
      mine   = create(:custom_report_run, custom_report: report, created_by_id: agent.id)
      create(:custom_report_run, custom_report: report, created_by_id: create(:agent).id)

      gql.execute(query)

      expect(gql.result.data.pluck('id')).to eq([Gql::ZammadSchema.id_from_object(mine)])
    end

    it 'returns nil for the progress while the total row count is unknown' do
      create(:custom_report_run, custom_report: report, created_by_id: agent.id, total_rows: nil)

      gql.execute(query)

      expect(gql.result.data.first['progressPercent']).to be_nil
    end

    it 'reports a pending run as not downloadable and without a path' do
      create(:custom_report_run, custom_report: report, created_by_id: agent.id)

      gql.execute(query)

      expect(gql.result.data.first).to include('downloadable' => false, 'downloadPath' => nil)
    end

    it 'honours the limit' do
      create_list(:custom_report_run, 3, custom_report: report, created_by_id: agent.id)

      gql.execute(query, variables: { limit: 2 })

      expect(gql.result.data.size).to eq(2)
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
