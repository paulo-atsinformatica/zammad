# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class TicketTimeTrackingsController < ApplicationController
  prepend_before_action :authentication_check
  prepend_before_action :check_time_tracking_permission, except: [:index]
  before_action :set_ticket
  before_action :check_ticket_access

  def start
    service = TicketTimeTrackingService.new(current_user: current_user, ticket: @ticket)
    result = service.start_tracking

    if result.success?
      render json: result.data.attributes_with_association_ids, status: :created
    else
      status_code = result.existing_ticket_id.present? ? :conflict : :unprocessable_entity
      response_data = {
        error: result.error,
        existing_ticket_id: result.existing_ticket_id,
        existing_ticket_number: result.existing_ticket_number
      }
      Rails.logger.info "Time tracking start error: #{response_data.inspect}"
      render json: response_data, status: status_code
    end
  end

  def pause
    service = TicketTimeTrackingService.new(current_user: current_user, ticket: @ticket)
    result = service.pause_tracking

    if result.success?
      render json: result.data.attributes_with_association_ids, status: :ok
    else
      render json: { error: result.error }, status: :unprocessable_entity
    end
  end

  def resume
    service = TicketTimeTrackingService.new(current_user: current_user, ticket: @ticket)
    result = service.resume_tracking

    if result.success?
      render json: result.data.attributes_with_association_ids, status: :ok
    else
      status_code = result.existing_ticket_id.present? ? :conflict : :unprocessable_entity
      render json: {
        error: result.error,
        existing_ticket_id: result.existing_ticket_id,
        existing_ticket_number: result.existing_ticket_number
      }, status: status_code
    end
  end

  def end
    service = TicketTimeTrackingService.new(current_user: current_user, ticket: @ticket)
    result = service.end_tracking

    if result.success?
      render json: result.data.attributes_with_association_ids, status: :ok
    else
      render json: { error: result.error }, status: :unprocessable_entity
    end
  end

  def current
    service = TicketTimeTrackingService.new(current_user: current_user, ticket: @ticket)
    result = service.current_tracking

    if result.data
      render json: result.data.attributes_with_association_ids, status: :ok
    else
      render json: { active: false }, status: :ok
    end
  end

  def index
    trackings = TicketTimeTracking.where(ticket_id: @ticket.id, user_id: current_user.id).recent
    render json: trackings.map(&:attributes_with_association_ids), status: :ok
  end

  def switch
    from_ticket = Ticket.find(params[:from_ticket_id])
    to_ticket = @ticket # Already set by before_action
    
    # Check access to both tickets
    authorize!(from_ticket, :show?)
    authorize!(to_ticket, :show?)

    service = TicketTimeTrackingService.new(ticket: to_ticket, current_user: current_user)
    result = service.switch_tracking(from_ticket, to_ticket)

    if result.success?
      render json: {
        new_tracking: result.data.attributes_with_association_ids,
        paused_tracking: result.paused_tracking&.attributes_with_association_ids
      }, status: :ok
    else
      render json: { error: result.error }, status: :unprocessable_entity
    end
  end

  private

  def check_time_tracking_permission
    return if current_user.permissions?('user.ticket_time_tracking')

    render json: { error: __('You do not have permission to track time on tickets.') }, status: :forbidden
  end

  def set_ticket
    @ticket = Ticket.find(params[:ticket_id]) if params[:ticket_id]
  end

  def check_ticket_access
    return unless @ticket
    
    # Check if user can access the ticket using show? policy
    authorize!(@ticket, :show?)
  end
end
