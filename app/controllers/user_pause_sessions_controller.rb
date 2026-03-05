# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class UserPauseSessionsController < ApplicationController
  prepend_before_action :authentication_check
  prepend_before_action :check_pause_control_permission

  def login
    active_session = UserPauseSession.active.find_by(user_id: current_user.id)
    if active_session
      render json: { logged_in: true, session: active_session.attributes_with_association_ids }, status: :ok
      return
    end

    session = UserPauseSession.create!(
      user: current_user,
      started_at: Time.zone.now,
      created_by_id: current_user.id,
      updated_by_id: current_user.id
    )

    render json: { logged_in: true, session: session.attributes_with_association_ids }, status: :created
  end

  def logout
    return render json: { error: __('Cannot logout while in pause') }, status: :unprocessable_entity if current_user.in_pause?

    active_session = UserPauseSession.active.find_by(user_id: current_user.id)
    return render json: { error: __('No active pause control session') }, status: :unprocessable_entity if active_session.blank?

    active_tracking = current_user.active_ticket_tracking
    if active_tracking
      active_tracking.pause_and_deactivate!
      current_user.update!(current_active_ticket_id: nil)
    end

    active_session.end_session!
    # Ao sair do controle de pausa, o usuário deve ficar explicitamente offline
    # e sem pausa ativa associada, para manter consistência de estado.
    current_user.update!(current_state: 'offline', current_pause_id: nil)

    render json: { logged_in: false, state: current_user.current_state }, status: :ok
  end

  def current
    active_session = UserPauseSession.active.find_by(user_id: current_user.id)
    if active_session
      render json: { logged_in: true, session: active_session.attributes_with_association_ids }, status: :ok
    else
      render json: { logged_in: false }, status: :ok
    end
  end

  private

  def check_pause_control_permission
    return if current_user.permissions?('user.pause_control')

    render json: { error: __('You do not have permission to use pause control.') }, status: :forbidden
  end
end
