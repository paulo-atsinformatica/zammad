# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class PauseType < ApplicationModel
  include HasHistory
  include ChecksHtmlSanitized
  include HasSearchIndexBackend
  include CanSelector
  include CanSearch

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :time_limit, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :color, format: { with: %r{\A#[0-9A-Fa-f]{6}\z}, message: 'must be a valid hex color code' }, allow_blank: true

  # Customização ATS: minutos de antecedência do aviso de fim de pausa. Em
  # branco desliga o aviso para este tipo.
  validates :warning_minutes, numericality: { greater_than: 0, only_integer: true }, allow_nil: true
  validate :warning_minutes_within_time_limit

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

  private

  # Avisar "faltam 10 minutos" numa pausa de 5 nunca dispararia, e avisar no
  # instante em que ela começa não é aviso. time_limit 0 é ilimitado, e aí não
  # existe fim para antecipar.
  def warning_minutes_within_time_limit
    return if warning_minutes.blank?

    if time_limit.to_i.zero?
      errors.add(:warning_minutes, __('cannot be set when the time limit is unlimited'))
      return
    end

    return if warning_minutes < time_limit

    errors.add(:warning_minutes, __('must be smaller than the time limit'))
  end
end
