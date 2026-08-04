class PauseIndicatorsActionsController < ApplicationController
  prepend_before_action :authentication_check
  prepend_before_action :authorize!

  def login
    user = find_user
    return head :not_found if user.blank?

    return render json: { success: true } if UserPauseSession.active.exists?(user_id: user.id)

    UserPauseSession.create!(user: user, started_at: Time.zone.now)
    PauseIndicatorsBroadcast.broadcast_change
    render json: { success: true }
  end

  def logout
    user = find_user
    return head :not_found if user.blank?

    active_session = UserPauseSession.active.find_by(user_id: user.id)
    if active_session
      active_session.update!(ended_at: Time.zone.now)
    end
    PauseIndicatorsBroadcast.broadcast_change
    render json: { success: true }
  end

  def start_pause
    user = find_user
    return head :not_found if user.blank?

    return render json: { success: true } if user.in_pause?

    pause_type = if params[:pause_type_id].present?
                   PauseType.find_by(id: params[:pause_type_id], active: true)
                 else
                   PauseType.where(active: true).order(:id).first
                 end

    service = UserPauseService.new(
      current_user:  user,
      pause_type_id: pause_type&.id,
      started_at:    Time.zone.now.iso8601,
    )

    result = service.start_pause
    if result.success?
      render json: { success: true }
    else
      render json: { success: false, error: result.error }, status: :unprocessable_entity
    end
  end

  def end_pause
    user = find_user
    return head :not_found if user.blank?

    # Se o limite de tempo foi excedido, garantimos uma justificativa mínima.
    delay_reason = params[:delay_reason].presence || __('Pause ended by supervisor')

    service = UserPauseService.new(
      current_user: user,
    )

    result = service.end_pause(
      delay_reason: delay_reason,
      ended_at:     Time.zone.now.iso8601,
    )

    if result.success?
      render json: { success: true }
    else
      render json: { success: false, error: result.error }, status: :unprocessable_entity
    end
  end

  def set_state
    user = find_user
    return head :not_found if user.blank?

    state = params[:state]
    return render json: { error: __('Invalid state') }, status: :unprocessable_entity if state.blank? || !%w[offline online].include?(state.to_s)

    if user.in_pause?
      return render json: { error: __('Cannot change state while in pause') }, status: :unprocessable_entity
    end

    user.update!(current_state: state)
    PauseIndicatorsBroadcast.broadcast_change
    render json: { state: user.current_state }, status: :ok
  end

  private

  def find_user
    User.find_by(id: params[:user_id])
  end
end

