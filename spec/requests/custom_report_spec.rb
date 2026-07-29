# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: relatório personalizado.

require 'rails_helper'

RSpec.describe 'CustomReport', type: :request do
  let(:admin)    { create(:admin) }
  let(:agent)    { create(:agent) }
  let!(:report)  { create(:custom_report, name: 'Tickets abertos', visibility: 'global') }

  # A tela Gerenciar > Relatórios Personalizados usa App.ControllerGenericIndex
  # com pagerAjax, que pagina pelo endpoint de search. Sem essa rota a tela nunca
  # carrega — foi exatamente o 404 que apareceu em produção.
  describe 'GET /api/v1/custom_reports/search' do
    it 'lists the reports for an admin' do
      authenticated_as(admin)
      get '/api/v1/custom_reports/search', params: { query: 'Tickets', full: true }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response['record_ids']).to include(report.id)
    end

    it 'returns every report, including inactive ones' do
      inactive = create(:custom_report, active: false)

      authenticated_as(admin)
      get '/api/v1/custom_reports/search', params: { full: true }, as: :json

      expect(json_response['record_ids']).to include(report.id, inactive.id)
    end

    it 'is forbidden for a user without admin.custom_report' do
      authenticated_as(agent)
      get '/api/v1/custom_reports/search', params: { full: true }, as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /api/v1/custom_reports/:id/generate' do
    it 'queues a run' do
      authenticated_as(admin)

      expect { post "/api/v1/custom_reports/#{report.id}/generate", params: { format: 'csv' }, as: :json }
        .to change(CustomReportRun, :count).by(1)

      expect(response).to have_http_status(:accepted)
    end

    it 'falls back to csv for an unknown format' do
      authenticated_as(admin)
      post "/api/v1/custom_reports/#{report.id}/generate", params: { format: 'pdf' }, as: :json

      expect(CustomReportRun.last.format).to eq('csv')
    end
  end
end
