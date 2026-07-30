# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: relatório personalizado.

require 'rails_helper'

RSpec.describe Gql::Mutations::CustomReport::Generate, type: :graphql do
  let(:group)  { create(:group) }
  let(:report) { create(:custom_report_general, groups: [group], columns: %w[number title]) }

  let(:mutation) do
    <<~MUTATION
      mutation customReportGenerate($customReportId: ID!, $format: String) {
        customReportGenerate(customReportId: $customReportId, format: $format) {
          customReportRun {
            id
            format
            status
            downloadable
            downloadPath
          }
          errors { message }
        }
      }
    MUTATION
  end

  let(:variables) { { customReportId: Gql::ZammadSchema.id_from_object(report), format: 'csv' } }

  # O papel Agent recebe report.custom no seed, então nada a conceder aqui.
  context 'with an agent allowed to use custom reports', authenticated_as: :agent do
    let(:agent) { create(:agent, groups: [group]) }

    it 'queues a run' do
      expect { gql.execute(mutation, variables:) }.to change(CustomReportRun, :count).by(1)
    end

    it 'returns the queued run as pending and not yet downloadable' do
      gql.execute(mutation, variables:)

      expect(gql.result.data['customReportRun'])
        .to include('status' => 'pending', 'format' => 'csv', 'downloadable' => false, 'downloadPath' => nil)
    end

    it 'attributes the run to the requesting user' do
      gql.execute(mutation, variables:)

      expect(CustomReportRun.last.created_by_id).to eq(agent.id)
    end

    it 'falls back to csv for an unknown format' do
      gql.execute(mutation, variables: variables.merge(format: 'pdf'))

      expect(CustomReportRun.last.format).to eq('csv')
    end
  end

  context 'with a report the user cannot see', authenticated_as: :agent do
    let(:agent)  { create(:agent) }
    let(:other)  { create(:agent) }
    let(:report) { create(:custom_report, visibility: 'personal', created_by_id: other.id) }

    it 'reports it as not found' do
      gql.execute(mutation, variables:)

      expect(gql.result.error_type).to eq(ActiveRecord::RecordNotFound)
    end

    it 'does not queue anything' do
      expect { gql.execute(mutation, variables:) }.not_to change(CustomReportRun, :count)
    end
  end

  context 'with a user lacking the custom report permission', authenticated_as: :customer do
    let(:customer) { create(:customer) }

    it 'is forbidden' do
      gql.execute(mutation, variables:)

      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end
end
