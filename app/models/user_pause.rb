# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class UserPause < ApplicationModel
  include HasHistory

  belongs_to :user
  belongs_to :pause_type, optional: true
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true

  validates :started_at, presence: true
  validates :time_limit, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validate :ended_at_after_started_at, if: -> { ended_at.present? }

  scope :active, -> { where(ended_at: nil) }
  scope :recent, -> { order(started_at: :desc) }

  def active?
    ended_at.nil?
  end

  def exceeded_time_limit?
    return false if !active?
    return false if time_limit.zero?

    duration_minutes >= time_limit
  end

  def duration_seconds
    end_time = ended_at || Time.zone.now
    (end_time - started_at).to_i
  end

  def duration_minutes
    duration_seconds / 60
  end

  def end_pause!(delay_reason: nil)
    return false if !active?

    self.ended_at = Time.zone.now
    self.delay_reason = delay_reason if delay_reason.present?
    save!
  end

  private

  def ended_at_after_started_at
    return if ended_at.blank? || started_at.blank?
    return if ended_at >= started_at

    errors.add(:ended_at, __('must be after started_at'))
  end
end



