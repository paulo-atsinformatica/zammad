# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class UserPauseService < Service::BaseWithCurrentUser
  def initialize(current_user:, pause_type_id: nil)
    super(current_user: current_user)
    @pause_type_id = pause_type_id
  end

  def start_pause
    return error(__('User does not have pause control enabled')) if !current_user.permissions?('user.pause_control')
    return error(__('User is not logged in to pause control')) if !pause_control_logged_in?
    return error(__('User is already in pause')) if current_user.in_pause?

    pause_type = @pause_type_id.present? ? PauseType.find_by(id: @pause_type_id, active: true) : nil
    time_limit = pause_type&.time_limit || 0

    # Pause any active ticket tracking
    active_tracking = current_user.active_ticket_tracking
    active_tracking&.pause!

    user_pause = UserPause.create!(
      user: current_user,
      pause_type: pause_type,
      started_at: Time.zone.now,
      time_limit: time_limit,
      created_by_id: current_user.id,
      updated_by_id: current_user.id
    )

    current_user.update!(
      current_state: 'pause',
      current_pause_id: user_pause.id
    )

    success(user_pause)
  end

  def end_pause(delay_reason: nil)
    return error(__('User is not logged in to pause control')) if !pause_control_logged_in?
    return error(__('User is not in pause')) if !current_user.in_pause?

    active_pause = current_user.active_pause
    return error(__('Active pause not found')) if active_pause.blank?

    # Check if time limit was exceeded
    if active_pause.exceeded_time_limit? && delay_reason.blank?
      return error(__('Delay reason is required when time limit is exceeded'))
    end

    active_pause.end_pause!(delay_reason: delay_reason)

    current_user.update!(
      current_state: 'online',
      current_pause_id: nil
    )

    # Offer to resume ticket tracking if it was paused
    active_tracking = current_user.active_ticket_tracking
    if active_tracking&.paused?
      success(active_pause, resume_tracking: true, tracking_id: active_tracking.id)
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

  def pause_control_logged_in?
    UserPauseSession.active.exists?(user_id: current_user.id)
  end

  def error(message)
    Service::Result.new(
      success: false,
      error: message
    )
  end

  def success(data, **options)
    Service::Result.new(
      success: true,
      data: data,
      **options
    )
  end
end

