class PublicPauseIndicatorsController < ApplicationController
  include ActionController::Live
  layout 'public_monitor', only: [:page]

  # Página HTML pública
  def page
  end

  # SSE: notifica o painel público quando o estado de pausa de qualquer usuário mudar (requer Redis).
  def stream
    unless redis_available?
      head :service_unavailable
      return
    end
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['X-Accel-Buffering'] = 'no'
    redis = Zammad::Service::Redis.new
    redis.subscribe(PauseIndicatorsBroadcast::CHANNEL) do |on|
      on.message do |_ch, _msg|
        begin
          response.stream.write("data: refresh\n\n")
        rescue IOError, Errno::EPIPE
          redis.unsubscribe
        end
      end
    end
  rescue IOError, Errno::EPIPE
    # Cliente desconectou
  ensure
    redis&.unsubscribe rescue nil
    redis&.close rescue nil
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
        .order(:firstname, :lastname)
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

    @redis_available = (Zammad::Service::Redis.new.ping == 'PONG' rescue false)
  end

  def build_public_entries_full
    users = base_scope
    users.map do |user|
      logged_in    = UserPauseSession.active.exists?(user_id: user.id)
      in_pause     = user.in_pause?
      state        = user.current_state || 'offline'
      active_pause = user.active_pause
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
      entry
    end
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

