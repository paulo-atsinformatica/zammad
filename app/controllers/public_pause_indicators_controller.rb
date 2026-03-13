class PublicPauseIndicatorsController < ApplicationController
  include ActionController::Live
  layout 'public_monitor', only: [:page]

  # Página HTML pública
  def page
  end

  # SSE: notifica o painel público quando o estado de pausa de qualquer usuário mudar (requer Redis).
  #
  # Usa PauseIndicatorsSseBroadcaster para compartilhar 1 conexão Redis por processo
  # entre todos os clientes SSE conectados, evitando Errno::EMFILE (Too many open files)
  # quando muitas abas estão abertas simultaneamente.
  def stream
    unless redis_available?
      head :service_unavailable
      return
    end

    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['X-Accel-Buffering'] = 'no'

    queue = PauseIndicatorsSseBroadcaster.subscribe

    loop do
      msg = queue.pop
      case msg
      when :refresh
        response.stream.write("data: refresh\n\n")
      when :heartbeat
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

