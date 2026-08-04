# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: relatório personalizado.

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # Modelos salvos de relatório
  #
  # A rota de search vem antes de /custom_reports/:id, senão 'search' seria
  # interpretado como um id.
  match api_path + '/custom_reports/search',       to: 'custom_reports#search',   via: %i[get post]

  match api_path + '/custom_reports',              to: 'custom_reports#index',    via: :get
  match api_path + '/custom_reports',              to: 'custom_reports#create',   via: :post
  match api_path + '/custom_reports/:id',          to: 'custom_reports#show',     via: :get
  match api_path + '/custom_reports/:id',          to: 'custom_reports#update',   via: %i[put patch]
  match api_path + '/custom_reports/:id',          to: 'custom_reports#destroy',  via: :delete

  # Página de resultados para o grid (leitura direta, sem fila)
  match api_path + '/custom_reports/:id/results',  to: 'custom_reports#results',  via: %i[get post]

  # Enfileira uma geração
  match api_path + '/custom_reports/:id/generate', to: 'custom_reports#generate', via: :post

  # Execuções: acompanhamento e download
  match api_path + '/custom_report_runs',               to: 'custom_reports#runs',     via: :get
  match api_path + '/custom_report_runs/:id',           to: 'custom_reports#run_show', via: :get
  match api_path + '/custom_report_runs/:id/download',  to: 'custom_reports#download', via: :get
end
