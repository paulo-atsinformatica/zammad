# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # Customização ATS: busca/perfil de "Grupo Econômico" (agrupamento por
  # Organization#nomegrupoeconomico), ver app/controllers/economic_groups_controller.rb.
  match api_path + '/economic_groups/search',
        to:  'economic_groups#search',
        via: :get

  match api_path + '/economic_groups/show',
        to:  'economic_groups#show',
        via: :get
end
