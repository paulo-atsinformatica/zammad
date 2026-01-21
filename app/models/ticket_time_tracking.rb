# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class TicketTimeTracking < ApplicationModel
  include HasHistory
  include ChecksClientNotification

  # Send notifications only to the user who owns the tracking
  client_notification_send_to :user_id

  belongs_to :ticket
  belongs_to :user
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true

  validates :started_at, presence: true
  validates :is_active, inclusion: { in: [true, false] }
  validate :only_one_active_per_user, on: :create

  # Callbacks for state change notifications
  after_save :broadcast_state_change
  after_destroy :broadcast_destroyed

  scope :active, -> { where(is_active: true) }
  scope :for_user, ->(user) { where(user_id: user.id) }
  scope :recent, -> { order(started_at: :desc) }

  def active?
    is_active && ended_at.nil?
  end

  def paused?
    paused_at.present? && resumed_at.nil? && ended_at.nil?
  end

  def pause!
    return false if !active? || paused?

    elapsed = Time.zone.now - (resumed_at || started_at)
    self.total_seconds = (total_seconds || 0) + elapsed.to_i

    self.paused_at = Time.zone.now
    self.resumed_at = nil # Clear resumed_at for new pause
    save!
  end

  # Pause and deactivate - used when switching to another ticket
  def pause_and_deactivate!
    return false if !is_active

    unless paused?
      elapsed = Time.zone.now - (resumed_at || started_at)
      self.total_seconds = (total_seconds || 0) + elapsed.to_i
      self.paused_at = Time.zone.now
      self.resumed_at = nil
    end

    self.is_active = false # Deactivate so new tracking can be created
    save!
  end

  # Reactivate a previously paused and deactivated tracking
  def reactivate!
    return false if is_active

    self.is_active = true
    self.resumed_at = Time.zone.now
    self.paused_at = nil # Clear paused state
    save!
  end

  def resume!
    return false if !paused?

    self.resumed_at = Time.zone.now
    self.paused_at = nil # Clear paused state to indicate running
    save!
  end

  def end!
    return false if !active?

    unless paused?
      elapsed = Time.zone.now - (resumed_at || started_at)
      self.total_seconds = (total_seconds || 0) + elapsed.to_i
    end

    self.ended_at = Time.zone.now
    self.is_active = false
    save!
  end

  def total_time_seconds
    base_seconds = total_seconds || 0
    return base_seconds if ended_at.present? || paused? || !is_active

    base_seconds + (Time.zone.now - (resumed_at || started_at)).to_i
  end

  def formatted_time
    seconds = total_time_seconds
    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    secs = seconds % 60
    format('%02d:%02d:%02d', hours, minutes, secs)
  end

  # Attribute to skip the active validation during switches
  attr_accessor :skip_active_validation

  # Current state as a simple string for frontend
  def current_state
    return 'ended' if ended_at.present?
    return 'paused' if paused?
    return 'running' if is_active

    'inactive'
  end

  # Override notify_clients_data_attributes to include more info
  def notify_clients_data_attributes
    {
      id:              id,
      ticket_id:       ticket_id,
      ticket_number:   ticket&.number,
      user_id:         user_id,
      is_active:       is_active,
      started_at:      started_at,
      paused_at:       paused_at,
      resumed_at:      resumed_at,
      ended_at:        ended_at,
      total_seconds:   total_time_seconds,
      current_state:   current_state,
      updated_at:      updated_at
    }
  end

  private

  def broadcast_state_change
    return if Setting.get('import_mode')

    # Broadcast to all sessions of this user
    message = {
      event: 'TicketTimeTracking:stateChange',
      data:  notify_clients_data_attributes
    }
    PushMessages.send_to(user_id, message)

    # Also broadcast a ticket-specific event for other users viewing the ticket
    ticket_message = {
      event: 'Ticket:timeTrackingChange',
      data:  {
        ticket_id:     ticket_id,
        user_id:       user_id,
        current_state: current_state,
        total_seconds: total_time_seconds,
        updated_at:    updated_at
      }
    }
    PushMessages.send(message: ticket_message, type: 'authenticated')
  end

  def broadcast_destroyed
    return if Setting.get('import_mode')

    message = {
      event: 'TicketTimeTracking:destroyed',
      data:  {
        id:        id,
        ticket_id: ticket_id,
        user_id:   user_id
      }
    }
    PushMessages.send_to(user_id, message)
  end

  def only_one_active_per_user
    return if !is_active
    return if skip_active_validation

    # Use a fresh query to check current DB state
    existing = self.class.where(user_id: user_id, is_active: true)
    existing = existing.where.not(id: id) if persisted?

    return if existing.reload.empty?

    errors.add(:base, __('User already has an active ticket time tracking'))
  end

end





