Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # Ações administrativas rápidas a partir do relatório de Indicadores de Pausa.
  match api_path + '/pause_indicators/login',
        to:   'pause_indicators_actions#login',
        via:  :post

  match api_path + '/pause_indicators/logout',
        to:   'pause_indicators_actions#logout',
        via:  :post

  match api_path + '/pause_indicators/start_pause',
        to:   'pause_indicators_actions#start_pause',
        via:  :post

  match api_path + '/pause_indicators/end_pause',
        to:   'pause_indicators_actions#end_pause',
        via:  :post

  match api_path + '/pause_indicators/set_state',
        to:   'pause_indicators_actions#set_state',
        via:  :post
end

