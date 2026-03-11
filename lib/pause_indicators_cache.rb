# frozen_string_literal: true

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
#
# Cache em Redis do snapshot de indicadores de pausa (relatório e painel público).
# Reduz carga no banco quando muitos usuários têm o relatório/painel abertos:
# em cada mudança de estado invalidamos o cache; as próximas requisições leem
# do Redis em vez de repetir dezenas de queries por request.
#
module PauseIndicatorsCache
  KEY_REPORT  = 'zammad:pause_indicators_report'
  KEY_PUBLIC  = 'zammad:public_pause_indicators'
  TTL_SECONDS = 60

  class << self
    def report_get
      return nil unless redis_available?

      raw = redis.get(KEY_REPORT)
      return nil if raw.blank?

      JSON.parse(raw, symbolize_names: true)
    rescue StandardError => e
      Rails.logger.warn "[PauseIndicatorsCache] report_get error: #{e.message}"
      nil
    end

    def report_set(payload)
      return unless redis_available?

      redis.set(KEY_REPORT, payload.to_json, ex: TTL_SECONDS)
    rescue StandardError => e
      Rails.logger.warn "[PauseIndicatorsCache] report_set error: #{e.message}"
    end

    def public_get
      return nil unless redis_available?

      raw = redis.get(KEY_PUBLIC)
      return nil if raw.blank?

      JSON.parse(raw, symbolize_names: true)
    rescue StandardError => e
      Rails.logger.warn "[PauseIndicatorsCache] public_get error: #{e.message}"
      nil
    end

    def public_set(payload)
      return unless redis_available?

      redis.set(KEY_PUBLIC, payload.to_json, ex: TTL_SECONDS)
    rescue StandardError => e
      Rails.logger.warn "[PauseIndicatorsCache] public_set error: #{e.message}"
    end

    def invalidate
      return unless redis_available?

      redis.del(KEY_REPORT, KEY_PUBLIC)
    rescue StandardError => e
      Rails.logger.warn "[PauseIndicatorsCache] invalidate error: #{e.message}"
    end

    def redis_available?
      return @redis_available if defined?(@redis_available)

      @redis_available = begin
        redis.ping == 'PONG'
      rescue StandardError
        false
      end
    end

    def redis
      @redis ||= Zammad::Service::Redis.new
    end
  end
end
