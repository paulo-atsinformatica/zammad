# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class UserStatesController < ApplicationController
  prepend_before_action :authentication_check

  def set
    state = params[:state]
    return render json: { error: __('Invalid state') }, status: :unprocessable_entity if !%w[offline online].include?(state)

    # Cannot set state if in pause - must end pause first
    if current_user.in_pause?
      return render json: { error: __('Cannot change state while in pause') }, status: :unprocessable_entity
    end

    current_user.update!(current_state: state)
    PauseIndicatorsBroadcast.broadcast_change
    render json: { state: current_user.current_state }, status: :ok
  end

  def current
    render json: {
      state: current_user.current_state,
      in_pause: current_user.in_pause?,
      pause: current_user.active_pause&.attributes_with_association_ids
    }, status: :ok
  end
end




