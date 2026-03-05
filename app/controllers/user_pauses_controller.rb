# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class UserPausesController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def start
    service = UserPauseService.new(
      current_user:   current_user,
      pause_type_id:  params[:pause_type_id],
      started_at:     params[:started_at]
    )
    result = service.start_pause

    if result.success?
      render json: result.data.attributes_with_association_ids, status: :created
    else
      render json: { error: result.error }, status: :unprocessable_entity
    end
  end

  def end
    service = UserPauseService.new(current_user: current_user)
    result = service.end_pause(delay_reason: params[:delay_reason], ended_at: params[:ended_at])

    if result.success?
      response_data = result.data.attributes_with_association_ids
      response_data[:resume_tracking] = result.resume_tracking if result.resume_tracking
      response_data[:tracking_id] = result.tracking_id if result.tracking_id
      render json: response_data, status: :ok
    else
      render json: { error: result.error }, status: :unprocessable_entity
    end
  end

  def current
    if current_user.in_pause?
      pause = current_user.active_pause
      render json: pause.attributes_with_association_ids, status: :ok
    else
      render json: { active: false }, status: :ok
    end
  end

  def index
    pauses = current_user.user_pauses.recent.limit(100)
    render json: pauses.map(&:attributes_with_association_ids), status: :ok
  end

  def check_time_limit
    service = UserPauseService.new(current_user: current_user)
    result = service.check_time_limit

    render json: { exceeded: result.data }, status: :ok
  end
end

