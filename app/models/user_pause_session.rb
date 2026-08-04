# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class UserPauseSession < ApplicationModel
  include HasHistory

  belongs_to :user
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true

  validates :started_at, presence: true
  validate :ended_at_after_started_at, if: -> { ended_at.present? }

  scope :active, -> { where(ended_at: nil) }
  scope :recent, -> { order(started_at: :desc) }

  def active?
    ended_at.nil?
  end

  def duration_seconds
    end_time = ended_at || Time.zone.now
    (end_time - started_at).to_i
  end

  def end_session!
    return false if !active?

    self.ended_at = Time.zone.now
    save!
  end

  private

  def ended_at_after_started_at
    return if ended_at.blank? || started_at.blank?
    return if ended_at >= started_at

    errors.add(:ended_at, __('must be after started_at'))
  end
end
