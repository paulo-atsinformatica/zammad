# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class PauseType < ApplicationModel
  include HasHistory
  include ChecksHtmlSanitized
  include HasSearchIndexBackend
  include CanSelector
  include CanSearch

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :time_limit, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :color, format: { with: /\A#[0-9A-Fa-f]{6}\z/, message: 'must be a valid hex color code' }, allow_blank: true

  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true

  has_many :user_pauses, dependent: :restrict_with_exception

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }

  sanitized_html :name

  def to_s
    name
  end

  def assets(data)
    return data if !data

    data['PauseType'] ||= {}
    data['PauseType'][id] = attributes_with_association_ids
    data
  end
end



