# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # Pause Types (Admin only)
  match api_path + '/pause_types', to: 'pause_types#index', via: :get
  match api_path + '/pause_types/search', to: 'pause_types#search', via: %i[get post]
  match api_path + '/pause_types/:id', to: 'pause_types#show', via: :get
  match api_path + '/pause_types', to: 'pause_types#create', via: :post
  match api_path + '/pause_types/:id', to: 'pause_types#update', via: :put
  match api_path + '/pause_types/:id', to: 'pause_types#destroy', via: :delete

  # User Pauses
  match api_path + '/user_pauses/start', to: 'user_pauses#start', via: :post
  match api_path + '/user_pauses/end', to: 'user_pauses#end', via: :post
  match api_path + '/user_pauses/current', to: 'user_pauses#current', via: :get
  match api_path + '/user_pauses', to: 'user_pauses#index', via: :get
  match api_path + '/user_pauses/check_time_limit', to: 'user_pauses#check_time_limit', via: :get

  # User Pause Sessions (Login/Logout)
  match api_path + '/user_pause_sessions/login', to: 'user_pause_sessions#login', via: :post
  match api_path + '/user_pause_sessions/logout', to: 'user_pause_sessions#logout', via: :post
  match api_path + '/user_pause_sessions/current', to: 'user_pause_sessions#current', via: :get

  # User States
  match api_path + '/user_states/set', to: 'user_states#set', via: :post
  match api_path + '/user_states/current', to: 'user_states#current', via: :get

  # Ticket Time Trackings
  match api_path + '/tickets/:ticket_id/time_tracking/start', to: 'ticket_time_trackings#start', via: :post
  match api_path + '/tickets/:ticket_id/time_tracking/pause', to: 'ticket_time_trackings#pause', via: :post
  match api_path + '/tickets/:ticket_id/time_tracking/resume', to: 'ticket_time_trackings#resume', via: :post
  match api_path + '/tickets/:ticket_id/time_tracking/end', to: 'ticket_time_trackings#end', via: :post
  match api_path + '/tickets/:ticket_id/time_tracking/current', to: 'ticket_time_trackings#current', via: :get
  # Antes da rota sem sufixo, senão 'summary' seria lido como parte dela.
  match api_path + '/tickets/:ticket_id/time_tracking/summary', to: 'ticket_time_trackings#summary', via: :get
  match api_path + '/tickets/:ticket_id/time_tracking', to: 'ticket_time_trackings#index', via: :get
  match api_path + '/tickets/:ticket_id/time_tracking/switch', to: 'ticket_time_trackings#switch', via: :post

  # User Pauses Reports
  match api_path + '/reports/user_pauses', to: 'user_pauses_reports#index', via: :get
  match api_path + '/reports/user_pauses/download', to: 'user_pauses_reports#download', via: :get

  # Ticket Time Trackings Reports
  match api_path + '/reports/ticket_time_trackings', to: 'ticket_time_trackings_reports#index', via: :get
  match api_path + '/reports/ticket_time_trackings/download', to: 'ticket_time_trackings_reports#download', via: :get

  # Pause Indicators Report
  match api_path + '/reports/pause_indicators', to: 'pause_indicators_reports#index', via: :get
end

