# frozen_string_literal: true

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
#
# Broadcaster SSE compartilhado para o painel público de indicadores de pausa.
#
# Problema resolvido:
#   A implementação anterior abria 1 conexão Redis bloqueante por aba do painel
#   (redis.subscribe é blocking). Com muitos usuários, isso esgotava os descritores
#   de arquivo do processo (Errno::EMFILE: Too many open files).
#
# Solução:
#   Um único thread por processo Rails mantém 1 conexão Redis inscrita no canal.
#   Cada conexão SSE recebe uma Queue local. Quando chega uma mensagem do Redis,
#   o broadcaster faz fan-out empurrando para todas as filas registradas.
#   Um thread de heartbeat periódico mantém as conexões SSE vivas para proxies
#   que fecham conexões silenciosas.
#
# Resultado:
#   N clientes SSE → 1 conexão Redis (era N conexões Redis).
#
module PauseIndicatorsSseBroadcaster
  HEARTBEAT_INTERVAL    = 25  # segundos — abaixo do timeout de maioria dos proxies (30s)
  MAX_RECONNECT_ATTEMPTS = 10 # tentativas consecutivas antes de parar o listener

  @mutex           = Mutex.new
  @queues          = []
  @listener_thread = nil
  @heartbeat_thread = nil

  class << self
    # Registra uma nova fila para um cliente SSE e garante que o listener Redis
    # e o heartbeat estejam rodando. Retorna a Queue que o controller deve usar.
    def subscribe
      queue = Queue.new
      @mutex.synchronize do
        @queues << queue
        ensure_listener_running
        ensure_heartbeat_running
      end
      queue
    end

    # Remove a fila quando o cliente SSE desconecta ou o controller encerra.
    def unsubscribe(queue)
      return if queue.nil?

      @mutex.synchronize { @queues.delete(queue) }
      queue.close rescue nil
    end

    # Envia uma mensagem de refresh para todos os clientes registrados.
    # Chamado pelo listener Redis; também pode ser chamado diretamente em testes.
    def fan_out(message = :refresh)
      @mutex.synchronize do
        @queues.reject! { |q| q.closed? rescue true }
        @queues.each { |q| q.push(message) rescue nil }
      end
    end

    private

    def ensure_listener_running
      return if @listener_thread&.alive?

      @listener_thread = Thread.new { listener_loop }
      @listener_thread.name = 'PauseIndicatorsSSEListener'
    end

    def ensure_heartbeat_running
      return if @heartbeat_thread&.alive?

      @heartbeat_thread = Thread.new { heartbeat_loop }
      @heartbeat_thread.name = 'PauseIndicatorsSSEHeartbeat'
    end

    # Loop único que mantém 1 conexão Redis por processo.
    # Backoff exponencial (2s, 4s, ... 30s cap) com limite de tentativas consecutivas.
    # Após MAX_RECONNECT_ATTEMPTS falhas sem sucesso, o thread encerra —
    # o próximo cliente que chamar subscribe() reiniciará o listener.
    def listener_loop
      consecutive_errors = 0
      loop do
        break if @mutex.synchronize { @queues.empty? }

        redis = nil
        begin
          redis = Zammad::Service::Redis.new
          redis.subscribe(PauseIndicatorsBroadcast::CHANNEL) do |on|
            on.message { |_ch, _msg| fan_out(:refresh) }
          end
          consecutive_errors = 0
        rescue Redis::BaseConnectionError, Redis::CommandError => e
          consecutive_errors += 1
          delay = [[2 * consecutive_errors, 30].min, 2].max
          Rails.logger.warn "[PauseIndicatorsSseBroadcaster] Redis error (#{consecutive_errors}/#{MAX_RECONNECT_ATTEMPTS}): #{e.message}. Retry in #{delay}s."
          if consecutive_errors >= MAX_RECONNECT_ATTEMPTS
            Rails.logger.error '[PauseIndicatorsSseBroadcaster] Max reconnect attempts reached. Stopping listener.'
            break
          end
          sleep delay
        rescue StandardError => e
          consecutive_errors += 1
          Rails.logger.error "[PauseIndicatorsSseBroadcaster] Unexpected error: #{e.message}. Retrying in 2s."
          sleep 2
        ensure
          redis&.close rescue nil
        end

        break unless @mutex.synchronize { @queues.any? }
      end
    ensure
      @mutex.synchronize { @listener_thread = nil }
    end

    # Envia heartbeat periódico para evitar que proxies fechem conexões silenciosas.
    #
    # ATENÇÃO: `break` dentro de um bloco `@mutex.synchronize { }` apenas quebra o
    # bloco (retorna do synchronize), NÃO o loop externo. Por isso o teste de saída
    # é feito FORA do synchronize, onde `break` realmente encerra o loop.
    def heartbeat_loop
      loop do
        sleep HEARTBEAT_INTERVAL

        empty = @mutex.synchronize do
          @queues.reject! { |q| q.closed? rescue true }
          @queues.each { |q| q.push(:heartbeat) rescue nil }
          @queues.empty?
        end

        break if empty
      end
    ensure
      @mutex.synchronize { @heartbeat_thread = nil }
    end
  end
end
