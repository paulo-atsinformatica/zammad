# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class UserPauseService < Service::Base
  def initialize(current_user:, pause_type_id: nil, started_at: nil)
    @current_user = current_user
    @pause_type_id = pause_type_id
    @started_at = started_at
  end

  def start_pause
    return error(__('User does not have pause control enabled')) if !current_user.permissions?('user.pause_control')
    return error(__('User is not logged in to pause control')) if !pause_control_logged_in?
    return error(__('User is already in pause')) if current_user.in_pause?

    active_pauses = current_user.user_pauses.active.to_a

    # Se houver pausas ativas "fantasmas" (no banco, mas o usuário não está em pausa),
    # encerramos automaticamente antes de criar uma nova. Isso corrige estados
    # inconsistentes herdados de versões anteriores sem exigir intervenção manual.
    if active_pauses.any? && !current_user.in_pause?
      active_pauses.each do |pause|
        pause.update!(
          ended_at:     Time.zone.now,
          delay_reason: pause.delay_reason.presence || __('Auto-closed stale pause by system')
        )
      end
      active_pauses = []
    end

    # Se após a correção ainda houver pausa ativa, tratamos como "já em pausa".
    if active_pauses.any?
      return error(__('User is already in pause'))
    end

    pause_type = @pause_type_id.present? ? PauseType.find_by(id: @pause_type_id, active: true) : nil
    time_limit = pause_type&.time_limit || 0

    # Usa horário enviado pelo cliente (quando clicou em "Iniciar pausa") para não perder tempo na espera da rede.
    started_at_time = parse_client_started_at(@started_at)

    # Pause any active ticket tracking
    active_tracking = current_user.active_ticket_tracking
    active_tracking&.pause!

    user_pause = nil
    begin
      ActiveRecord::Base.transaction do
        user_pause = UserPause.create!(
          user:          current_user,
          pause_type:    pause_type,
          started_at:    started_at_time,
          time_limit:    time_limit,
          created_by_id: current_user.id,
          updated_by_id: current_user.id
        )
        current_user.update!(
          current_state:    'pause',
          current_pause_id: user_pause.id
        )
      end
    rescue ActiveRecord::RecordNotUnique => e
      Rails.logger.warn "[UserPauseService] Active pause already exists for user #{current_user.id}: #{e.message}"
      return error(__('User is already in pause'))
    end

    PauseIndicatorsBroadcast.broadcast_change
    success(user_pause)
  end

  def end_pause(delay_reason: nil, ended_at: nil)
    return error(__('User is not logged in to pause control')) if !pause_control_logged_in?

    # Idempotente: se já não está em pausa (ex.: outra aba encerrou), retorna sucesso para não gerar 422
    if !current_user.in_pause?
      last_pause = current_user.user_pauses.recent.first
      return success(last_pause) if last_pause.present?

      return error(__('User is not in pause'))
    end

    active_pause = current_user.active_pause
    return error(__('Active pause not found')) if active_pause.blank?

    # Usa o horário enviado pelo cliente (momento do clique em "Sair da pausa")
    # para determinar se o tempo limite foi excedido, evitando penalizar por
    # latência de rede ou processamento no servidor.
    proposed_end_time = active_pause.parse_client_ended_at(ended_at)

    # Check if time limit was exceeded at the moment of click
    if active_pause.exceeded_time_limit_at?(proposed_end_time) && delay_reason.blank?
      return error(__('Delay reason is required when time limit is exceeded'))
    end

    ActiveRecord::Base.transaction do
      active_pause.end_pause!(delay_reason: delay_reason, ended_at: proposed_end_time)
      current_user.update!(
        current_state:    'online',
        current_pause_id: nil
      )
    end

    PauseIndicatorsBroadcast.broadcast_change
    # Oferece retomar a contagem que a pausa interrompeu.
    #
    # Lê resumable_ticket_tracking e não active_ticket_tracking: pausar desliga
    # is_active, então a contagem interrompida não está mais entre as ativas.
    paused_tracking = current_user.resumable_ticket_tracking
    if paused_tracking.present?
      success(active_pause, resume_tracking: true, tracking_id: paused_tracking.id)
    else
      success(active_pause)
    end
  end

  def check_time_limit
    return success(false) if !pause_control_logged_in?
    return success(false) if !current_user.in_pause?

    active_pause = current_user.active_pause
    return success(false) if active_pause.blank?

    success(active_pause.exceeded_time_limit?)
  end

  def force_end_pause_if_exceeded
    return success(false) if !pause_control_logged_in?
    return success(false) if !current_user.in_pause?

    active_pause = current_user.active_pause
    return success(false) if active_pause.blank?
    return success(false) if !active_pause.exceeded_time_limit?

    # Force end pause - this should trigger UI to show delay reason modal
    success(true, pause: active_pause)
  end

  private

  def parse_client_started_at(client_started_at)
    return Time.zone.now if client_started_at.blank?

    t = Time.zone.parse(client_started_at.to_s)
    return Time.zone.now if t.blank?
    # Não aceita futuro
    return Time.zone.now if t > Time.zone.now
    # Não aceita mais que 5 minutos no passado (evita abuso; atraso de rede raramente > 1 min)
    return 5.minutes.ago if t < 5.minutes.ago

    t
  end

  def pause_control_logged_in?
    UserPauseSession.active.exists?(user_id: current_user.id)
  end

  def error(message)
    Service::Result.new(
      success: false,
      error:   message
    )
  end

  def success(data, **)
    Service::Result.new(
      success: true,
      data:    data,
      **
    )
  end
end
