# frozen_string_literal: true

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
#
# Notifica clientes quando o estado de pausa de qualquer usuário mudar,
# para que o Relatório de Indicadores de Pausa e o painel público atualizem em tempo real.
#
module PauseIndicatorsBroadcast
  CHANNEL = 'zammad:pause_indicators_changed'

  class << self
    def broadcast_change
      # Invalida cache de indicadores para que a próxima leitura seja do banco
      PauseIndicatorsCache.invalidate if defined?(PauseIndicatorsCache)
      # WebSocket: todos os clientes autenticados e públicos (SPA) recebem e disparam App.Event.trigger('pause_indicators:changed')
      Sessions.broadcast(
        { event: 'pause_indicators:changed', data: {} },
        'public'
      )
      # Redis pub/sub: endpoint SSE do painel público (sem WebSocket) recebe e notifica EventSource
      publish_redis if redis_available?
    rescue StandardError => e
      Rails.logger.error "[PauseIndicatorsBroadcast] #{e.message}"
    end

    private

    # Sem memoização permanente: se o Redis cair e voltar, o broadcast
    # recupera automaticamente sem precisar reiniciar o processo.
    def redis_available?
      Zammad::Service::Redis.new.ping == 'PONG'
    rescue StandardError
      false
    end

    def publish_redis
      Zammad::Service::Redis.new.publish(CHANNEL, '1')
    end
  end
end
