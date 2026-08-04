Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  # JSON público para painel externo de indicadores de pausa
  match api_path + '/public_pause_indicators',
        to:   'public_pause_indicators#index',
        via:  :get

  # SSE: stream de eventos para atualização em tempo real do painel (requer Redis).
  match api_path + '/public_pause_indicators/stream',
        to:   'public_pause_indicators#stream',
        via:  :get

  # Página HTML pública (externa ao app principal) para visualização em tempo real.
  # Usamos um caminho sem prefixo /public para evitar conflitos com servidores que servem arquivos estáticos dessa pasta.
  match '/monitor/pause_indicators',
        to:   'public_pause_indicators#page',
        via:  :get
end

