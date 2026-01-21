# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class TicketTimeTrackingService < Service::BaseWithCurrentUser
  def initialize(current_user:, ticket:)
    super(current_user: current_user)
    @ticket = ticket
  end

  def start_tracking
    return error(__('User does not have time tracking enabled')) if !current_user.permissions?('user.ticket_time_tracking')
    return error(__('User is in pause')) if current_user.in_pause?
    return error(__('Ticket is closed')) if @ticket.state&.state_type&.name == 'closed'
    return error(__('Ticket is not assigned to user')) if @ticket.owner_id != current_user.id

    # Check if user already has an active tracking
    existing_tracking = current_user.active_ticket_tracking
    if existing_tracking.present?
      return error(
        __('User already has an active ticket time tracking'),
        existing_ticket_id: existing_tracking.ticket_id,
        existing_ticket_number: existing_tracking.ticket.number
      )
    end

    tracking = TicketTimeTracking.create!(
      ticket: @ticket,
      user: current_user,
      started_at: Time.zone.now,
      is_active: true,
      created_by_id: current_user.id,
      updated_by_id: current_user.id
    )

    current_user.update!(current_active_ticket_id: @ticket.id)

    success(tracking)
  end

  def pause_tracking
    tracking = find_active_tracking
    return tracking if !tracking[:success]

    tracking_obj = tracking[:data]
    tracking_obj.pause!

    success(tracking_obj)
  end

  def resume_tracking
    return error(__('User does not have time tracking enabled')) if !current_user.permissions?('user.ticket_time_tracking')
    return error(__('User is in pause')) if current_user.in_pause?
    return error(__('Ticket is closed')) if @ticket.state&.state_type&.name == 'closed'
    return error(__('Ticket is not assigned to user')) if @ticket.owner_id != current_user.id

    # First try to find active paused tracking for THIS ticket
    tracking_obj = TicketTimeTracking.active.find_by(ticket: @ticket, user: current_user)
    
    # If not found, check for deactivated tracking (from closed ticket or switch)
    if tracking_obj.blank?
      tracking_obj = TicketTimeTracking.find_by(
        ticket: @ticket,
        user: current_user,
        is_active: false,
        ended_at: nil
      )
    end

    return error(__('No tracking found to resume')) if tracking_obj.blank?

    # IMPORTANT: Check if user has ANOTHER active tracking (different ticket)
    # This must be checked AFTER finding the tracking for this ticket
    existing_active = current_user.active_ticket_tracking
    if existing_active.present? && existing_active.ticket_id != @ticket.id
      return error(
        __('User already has an active ticket time tracking'),
        existing_ticket_id: existing_active.ticket_id,
        existing_ticket_number: existing_active.ticket.number
      )
    end

    # Reactivate the tracking
    if tracking_obj.is_active
      # Just paused, simple resume
      return error(__('Tracking is not paused')) if !tracking_obj.paused?
      tracking_obj.resume!
    else
      # Was deactivated (from closed ticket or switch), reactivate
      tracking_obj.reactivate!
    end

    current_user.update!(current_active_ticket_id: @ticket.id)

    success(tracking_obj)
  end

  def end_tracking
    tracking = find_active_tracking
    return tracking if !tracking[:success]

    tracking_obj = tracking[:data]
    tracking_obj.end!

    current_user.update!(current_active_ticket_id: nil) if current_user.current_active_ticket_id == @ticket.id

    success(tracking_obj)
  end

  def switch_tracking(from_ticket, to_ticket)
    return error(__('User is in pause')) if current_user.in_pause?
    return error(__('Ticket is not assigned to user')) if to_ticket.owner_id != current_user.id

    from_tracking = TicketTimeTracking.active.find_by(ticket: from_ticket, user: current_user)
    return error(__('Source ticket tracking not found')) if from_tracking.blank?

    # Check if target ticket has an inactive but paused tracking (can be resumed)
    paused_tracking = TicketTimeTracking.find_by(ticket: to_ticket, user: current_user, is_active: false)
    if paused_tracking.present? && paused_tracking.paused_at.present?
      # Resume the paused tracking for target ticket
      TicketTimeTracking.transaction do
        from_tracking.pause_and_deactivate!
        paused_tracking.reactivate!
        current_user.update!(current_active_ticket_id: to_ticket.id)
      end
      return success(paused_tracking, paused_tracking: from_tracking)
    end

    # Check if target ticket already has active tracking
    existing_tracking = TicketTimeTracking.active.find_by(ticket: to_ticket, user: current_user)
    return error(__('Target ticket already has active tracking')) if existing_tracking.present?

    new_tracking = nil
    TicketTimeTracking.transaction do
      # First, deactivate the source tracking
      from_tracking.pause_and_deactivate!
      
      # Now create the new tracking with validation skipped (we already checked)
      new_tracking = TicketTimeTracking.new(
        ticket: to_ticket,
        user: current_user,
        started_at: Time.zone.now,
        is_active: true,
        total_seconds: 0,
        created_by_id: current_user.id,
        updated_by_id: current_user.id
      )
      new_tracking.skip_active_validation = true
      new_tracking.save!

      current_user.update!(current_active_ticket_id: to_ticket.id)
    end

    success(new_tracking, paused_tracking: from_tracking)
  end

  def current_tracking
    # First check for active tracking
    tracking = TicketTimeTracking.active.find_by(ticket: @ticket, user: current_user)
    return success(tracking) if tracking.present?

    # Check for paused tracking (including closed tickets) to show elapsed time
    paused_tracking = TicketTimeTracking.find_by(
      ticket: @ticket,
      user: current_user,
      is_active: false,
      ended_at: nil
    )
    if paused_tracking.present? && paused_tracking.paused_at.present?
      # Return paused tracking info so frontend shows time; resume remains blocked if closed
      return success(paused_tracking)
    end

    success(nil)
  end

  private

  def find_active_tracking
    tracking = TicketTimeTracking.active.find_by(ticket: @ticket, user: current_user)
    return error(__('Active tracking not found')) if tracking.blank?

    success(tracking)
  end

  def error(message, **options)
    Service::Result.new(
      success: false,
      error: message,
      **options
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

