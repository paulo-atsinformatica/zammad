# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class PublicPauseIndicatorsController < ApplicationController
  include ActionController::Live

  layout 'public_monitor', only: [:page]

  # Duração máxima de uma conexão SSE antes de encerrar graciosamente.
  # O EventSource do browser reconecta automaticamente — isso garante rotatividade
  # de threads do Puma e evita que conexões zumbi acumulem indefinidamente.
  SSE_MAX_DURATION = 300 # segundos (5 minutos)

  # Timeout de pop da fila por iteração. Garante que o Puma thread acorde
  # periodicamente e detecte clientes desconectados mesmo se o broadcaster
  # falhar (ex.: thread de heartbeat encerrado por exceção).
  SSE_POP_TIMEOUT = 30 # segundos

  # Página HTML pública
  def page; end

  # SSE: notifica o painel público quando o estado de pausa de qualquer usuário mudar (requer Redis).
  #
  # Usa PauseIndicatorsSseBroadcaster para compartilhar 1 conexão Redis por processo
  # entre todos os clientes SSE conectados, evitando Errno::EMFILE (Too many open files)
  # quando muitas abas estão abertas simultaneamente.
  #
  # O loop usa queue.pop com timeout para garantir que o Puma thread NÃO fique
  # bloqueado indefinidamente. Mesmo que o broadcaster pare de enviar heartbeats,
  # o thread acordará a cada SSE_POP_TIMEOUT segundos, escreverá um heartbeat e
  # detectará clientes desconectados via IOError/Errno::EPIPE.
  def stream
    unless redis_available?
      head :service_unavailable
      return
    end

    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['X-Accel-Buffering'] = 'no'

    queue    = PauseIndicatorsSseBroadcaster.subscribe
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + SSE_MAX_DURATION

    loop do
      remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
      break if remaining <= 0

      msg = queue.pop(timeout: [remaining, SSE_POP_TIMEOUT].min)

      case msg
      when :refresh
        response.stream.write("data: refresh\n\n")
      when :heartbeat
        response.stream.write(": heartbeat\n\n")
      when nil
        # pop atingiu o timeout — escreve heartbeat para detectar clientes desconectados
        response.stream.write(": heartbeat\n\n")
      end
    end
  rescue IOError, Errno::EPIPE, Redis::BaseConnectionError
    # Cliente desconectou ou Redis caiu — encerra graciosamente
  ensure
    PauseIndicatorsSseBroadcaster.unsubscribe(queue)
    response.stream.close if response.stream.respond_to?(:close)
  end

  # API pública em JSON para o painel externo
  def index
    cached = PauseIndicatorsCache.redis_available? ? PauseIndicatorsCache.public_get : nil

    if cached
      entries = filter_public_entries(cached[:entries] || [], params)
      render json: {
        entries: entries,
        agents:  cached[:agents] || [],
        teams:   cached[:teams] || []
      }, status: :ok
      return
    end

    # Cache miss: monta payload completo, cacheia e aplica filtros em memória
    full_entries = build_public_entries_full
    agents = agents_list
    teams = teams_list
    PauseIndicatorsCache.public_set(entries: full_entries, agents: agents, teams: teams)

    entries = filter_public_entries(full_entries, params)

    render json: {
      entries: entries,
      agents:  agents,
      teams:   teams
    }, status: :ok
  end

  private

  # Mesmos papéis do relatório interno: quem tem permissão user.pause_control (exceto Admin/Customer)
  def eligible_role_ids
    @eligible_role_ids ||= Role.joins(:permissions)
                               .where(permissions: { name: 'user.pause_control', active: true }, roles: { active: true })
                               .where.not(roles: { name: %w[Admin Customer] })
                               .pluck(:id)
  end

  def base_scope
    User.joins(:roles)
        .where(roles: { id: eligible_role_ids })
        .where(users: { active: true })
        .distinct
        .includes(:roles)
  end

  def build_status(logged_in, in_pause, state)
    if !logged_in
      __('Deslogado')
    elsif in_pause
      __('Em pausa')
    elsif state == 'offline'
      __('Offline')
    else
      __('Online')
    end
  end

  def agents_list
    User.joins(:roles)
        .where(roles: { id: eligible_role_ids })
        .where(users: { active: true })
        .distinct
        .reorder(:firstname, :lastname)
        .map { |u| { id: u.id, name: "#{u.firstname} #{u.lastname}".strip.presence || u.login } }
  end

  def teams_list
    return [] unless user_equipe_attribute?

    base_scope
      .where.not(equipe: nil)
      .where.not(equipe: '')
      .distinct
      .pluck(:equipe)
      .compact
      .reject(&:blank?)
      .sort
      .map { |name| { id: name, name: name } }
  end

  def user_equipe_attribute?
    @user_equipe_attribute ||= User.column_names.include?('equipe')
  end

  def redis_available?
    return @redis_available if defined?(@redis_available)

    @redis_available = begin
      Zammad::Service::Redis.new.ping == 'PONG'
    rescue
      false
    end
  end

  def build_public_entries_full
    user_list = base_scope.to_a

    # Carrega sessões ativas em lote (substitui N chamadas exists? por 1 query)
    logged_in_ids = UserPauseSession.active
                                    .where(user_id: user_list.map(&:id))
                                    .pluck(:user_id)
                                    .to_set

    # Carrega pausas ativas com pause_type em lote (substitui N find_by + N eager load)
    active_pause_ids = user_list.map(&:current_pause_id).compact
    pauses_by_id     = UserPause.includes(:pause_type)
                                .where(id: active_pause_ids, ended_at: nil)
                                .index_by(&:id)

    trackings_by_user_id = active_trackings_by_user_id(user_list)

    user_list.map do |user|
      logged_in    = logged_in_ids.include?(user.id)
      active_pause = user.current_pause_id ? pauses_by_id[user.current_pause_id] : nil
      in_pause     = user.current_state == 'pause' && active_pause.present?
      state        = user.current_state || 'offline'

      entry = {
        id:               user.id,
        name:             "#{user.firstname} #{user.lastname}".strip.presence || user.login,
        status:           build_status(logged_in, in_pause, state),
        logged_in:        logged_in,
        in_pause:         in_pause,
        state:            state,
        pause_name:       active_pause&.pause_type&.name,
        pause_started_at: active_pause&.started_at&.iso8601
      }
      entry[:equipe] = user.equipe.to_s if user_equipe_attribute?
      entry.merge!(tracking_attributes(trackings_by_user_id[user.id]))
      entry
    end
  end

  # Contagem de tempo em curso, em lote. O ticket e a organização vêm no
  # includes porque as colunas de atendimento mostram os dois — sem isso seriam
  # duas queries por usuário.
  def active_trackings_by_user_id(user_list)
    TicketTimeTracking.active
                      .where(user_id: user_list.map(&:id))
                      .includes(ticket: :organization)
                      .index_by(&:user_id)
  end

  # Colunas de atendimento em curso. O tempo vai em duas partes — acumulado
  # persistido e início do trecho corrente — porque o painel soma o segundo a
  # segundo no navegador, como já faz com o tempo de pausa. Mandar um total
  # pronto congelaria o cronômetro entre um refresh e outro.
  def tracking_attributes(tracking)
    return empty_tracking_attributes if tracking.blank?

    ticket = tracking.ticket
    return empty_tracking_attributes if ticket.blank?

    {
      tracking_ticket_number: ticket.number,
      tracking_organization:  ticket.organization&.name,
      tracking_total_seconds: tracking.total_seconds.to_i,
      tracking_started_at:    (tracking.resumed_at || tracking.started_at)&.iso8601
    }
  end

  def empty_tracking_attributes
    {
      tracking_ticket_number: nil,
      tracking_organization:  nil,
      tracking_total_seconds: nil,
      tracking_started_at:    nil
    }
  end

  def filter_public_entries(entries, req_params)
    if req_params[:user_ids].present?
      ids = Array(req_params[:user_ids]).reject(&:blank?).map(&:to_i)
      entries = entries.select { |e| ids.include?(e[:id].to_i) } if ids.any?
    end
    if req_params[:equipes].present?
      equipes = Array(req_params[:equipes]).reject(&:blank?).map(&:to_s).map(&:strip)
      entries = entries.select { |e| equipes.include?((e[:equipe] || '').to_s) } if equipes.any?
    end
    if req_params[:logged_state].present?
      entries = case req_params[:logged_state]
                when 'logged_in' then entries.select { |e| e[:logged_in] }
                when 'logged_out' then entries.reject { |e| e[:logged_in] }
                else entries
                end
    end
    entries
  end
end
