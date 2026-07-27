# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class RackAttackSetup
  class PublicEndpoint
    # Customização ATS: limites acima do padrão upstream (3) para reduzir 429 em
    # ambientes com NAT/proxy ou múltiplos cliques do usuário.
    LIMIT_PER_FIELD = 10
    LIMIT_PER_IP    = 30
    PERIOD          = 1.minute.to_i
    ENDPOINTS = [
      {
        url:   '/api/v1/users/password_reset',
        field: 'username',
      },
      {
        url:   '/api/v1/users/email_verify_send',
        field: 'email',
      },
      {
        url:   '/api/v1/users/admin_password_auth',
        field: 'username',
      },
    ].freeze

    def self.setup_ip_throttling(url)
      Rack::Attack.throttle("limit #{url} requests per source IP address", limit: LIMIT_PER_IP, period: PERIOD) do |req|
        next if !req.post?
        next if !RackAttackSetup.path_matches?(req.path, url)

        req.ip
      end
    end

    def self.setup_field_throttling(url, field)
      Rack::Attack.throttle("limit #{url} requests per #{field}", limit: LIMIT_PER_FIELD, period: PERIOD) do |req|
        next if !req.post?
        next if !RackAttackSetup.path_matches?(req.path, url)

        RackAttackSetup.normalize_param(req.params[field])
      end
    end

    def self.setup
      ENDPOINTS.each do |config|
        setup_field_throttling(config[:url], config[:field])
        setup_ip_throttling(config[:url])
      end
    end
  end
end
