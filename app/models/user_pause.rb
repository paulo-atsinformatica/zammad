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

  # Mantém o estado do usuário consistente quando a pausa é encerrada por fora do service.
  after_save :sync_user_state_after_end

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

  def end_pause!(delay_reason: nil, ended_at: nil)
    return false if !active?

    self.ended_at = parse_client_ended_at(ended_at)
    self.delay_reason = delay_reason if delay_reason.present?
    save!
  end

  # Usa horário enviado pelo cliente (quando clicou em "Sair da pausa") para não penalizar por latência/rede.
  def parse_client_ended_at(client_ended_at)
    return Time.zone.now if client_ended_at.blank?

    t = Time.zone.parse(client_ended_at.to_s)
    return Time.zone.now if t.blank?
    return Time.zone.now if t > Time.zone.now
    return started_at if t < started_at

    t
  end

  private

  def ended_at_after_started_at
    return if ended_at.blank? || started_at.blank?
    return if ended_at >= started_at

    errors.add(:ended_at, __('must be after started_at'))
  end

  def sync_user_state_after_end
    return if ended_at_before_last_save.nil?
    return if ended_at_before_last_save.present? # já estava encerrada
    return if ended_at.blank?
    return if user.blank?

    # Se esta pausa era a pausa atual do usuário, volta para online e limpa referência.
    if user.current_pause_id == id
      user.update_columns(
        current_state:    'online',
        current_pause_id: nil,
        updated_at:       Time.zone.now,
      )
    end
  end
end



