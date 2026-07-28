# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: relatório personalizado.

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # Modelos salvos de relatório
  match api_path + '/custom_reports',              to: 'custom_reports#index',    via: :get
  match api_path + '/custom_reports',              to: 'custom_reports#create',   via: :post
  match api_path + '/custom_reports/:id',          to: 'custom_reports#show',     via: :get
  match api_path + '/custom_reports/:id',          to: 'custom_reports#update',   via: %i[put patch]
  match api_path + '/custom_reports/:id',          to: 'custom_reports#destroy',  via: :delete

  # Enfileira uma geração
  match api_path + '/custom_reports/:id/generate', to: 'custom_reports#generate', via: :post

  # Execuções: acompanhamento e download
  match api_path + '/custom_report_runs',               to: 'custom_reports#runs',     via: :get
  match api_path + '/custom_report_runs/:id',           to: 'custom_reports#run_show', via: :get
  match api_path + '/custom_report_runs/:id/download',  to: 'custom_reports#download', via: :get
end
