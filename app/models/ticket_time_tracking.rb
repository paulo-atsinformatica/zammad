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

  # Também on: :update — reactivate! liga is_active num registro já existente, e
  # com a validação só na criação esse caminho podia abrir uma segunda contagem
  # ativa para o mesmo usuário.
  validate :only_one_active_per_user, on: %i[create update]

  # Callbacks for state change notifications
  after_save :broadcast_state_change
  after_destroy :broadcast_destroyed

  # `active` significa "ocupa o slot único do usuário e está correndo". Uma
  # contagem pausada NÃO é ativa: pause! desliga is_active justamente para
  # liberar o usuário a iniciar outro ticket.
  scope :active, -> { where(is_active: true) }

  # Pausada e ainda não encerrada — o que resume_tracking consegue retomar.
  scope :resumable, -> { where(is_active: false, ended_at: nil).where.not(paused_at: nil) }

  scope :for_user, ->(user) { where(user_id: user.id) }
  scope :recent, -> { order(started_at: :desc) }

  # Teto para uma contagem em curso, em horas. Acima disso ela é encerrada
  # automaticamente pelo Scheduler.
  DEFAULT_MAX_RUNNING_HOURS = 12

  def active?
    is_active && ended_at.nil?
  end

  # Encerra contagens deixadas correndo. Chamado pelo Scheduler.
  #
  # Sem isto, um agente que inicia a contagem e fecha o navegador deixa o
  # cronômetro correndo por noites e fins de semana inteiros, e esse tempo entra
  # no relatório como atendimento. Não havia limite nenhum.
  #
  # O corte é pelo início do segmento em curso (resumed_at, ou started_at na
  # primeira vez), e não por started_at sempre: uma contagem legitimamente
  # retomada hoje não deve morrer porque começou semana passada.
  def self.close_stale
    limit = max_running_hours
    return 0 if limit <= 0

    threshold = limit.hours.ago
    closed = 0

    active.where(ended_at: nil).find_each do |tracking|
      next if (tracking.resumed_at || tracking.started_at) > threshold

      tracking.end!
      tracking.user&.update_columns(current_active_ticket_id: nil) # rubocop:disable Rails/SkipsModelValidations
      closed += 1
    rescue => e
      Rails.logger.error "Could not close stale time tracking #{tracking.id}: #{e.message}"
    end

    Rails.logger.info "Closed #{closed} stale ticket time tracking(s)." if closed.positive?
    closed
  end

  def self.max_running_hours
    (Setting.get('ticket_time_tracking_max_running_hours').presence || DEFAULT_MAX_RUNNING_HOURS).to_i
  end

  def paused?
    paused_at.present? && resumed_at.nil? && ended_at.nil?
  end

  # Pausar também libera o slot (is_active = false).
  #
  # Antes a pausa mantinha is_active, e como a guarda de "já tem contagem ativa"
  # olha esse campo, pausar um ticket não liberava o usuário para iniciar outro —
  # ele recebia "Você já está atendendo o ticket #X" mesmo tendo pausado.
  # Retomar continua funcionando: resume_tracking encontra a contagem pelo escopo
  # `resumable` e chama reactivate!.
  def pause!
    return false if !active? || paused?

    accumulate_elapsed
    self.paused_at = Time.zone.now
    self.resumed_at = nil # Clear resumed_at for new pause
    self.is_active = false
    save!
  end

  # Mantido como nome próprio para a troca de ticket, mas hoje é o mesmo que
  # pause!: os dois pausam e liberam o slot.
  alias pause_and_deactivate! pause!

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

  # Encerra qualquer contagem ainda aberta, inclusive a que foi pausada ou
  # desativada por troca de ticket.
  #
  # Antes exigia `active?`, então uma contagem pausada ficava em limbo: não dava
  # para encerrar por lugar nenhum e acumulava com ended_at nulo para sempre.
  def end!
    return false if ended_at.present?

    accumulate_elapsed if !paused?

    self.ended_at = Time.zone.now
    self.is_active = false
    save!
  end

  def total_time_seconds
    base_seconds = total_seconds || 0
    return base_seconds if ended_at.present? || paused? || !is_active

    base_seconds + (Time.zone.now - (resumed_at || started_at)).to_i
  end

  # Tudo o que este usuário já acumulou NESTE ticket, somando os intervalos
  # anteriores que foram encerrados.
  #
  # Existe porque cada passagem pelo ticket vira um registro próprio: quando o
  # ticket vai para outro dono e volta, o novo registro começa do zero e o agente
  # veria 00:00:00 apesar de já ter trabalhado nele. Os registros continuam
  # separados de propósito — é o que permite ver o tempo por atendente e por
  # passagem — e a soma acontece só na exibição.
  #
  # Não inclui o segmento em curso: o cliente soma isso sozinho a partir de
  # resumed_at/started_at, como já faz com total_seconds.
  def ticket_total_seconds
    previous = self.class
      .where(ticket_id: ticket_id, user_id: user_id)
      .where.not(id: id)
      .sum(:total_seconds)

    previous + (total_seconds || 0)
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
  #
  # `total_seconds` is deliberately the persisted accumulator (same meaning as
  # the DB column and as the REST responses, which serialize raw attributes).
  # Clients add the live segment themselves from resumed_at/started_at, so
  # sending the computed total here would make them count it twice.
  # `total_time_seconds` carries the computed live total for consumers that
  # want a ready-to-display value.
  def notify_clients_data_attributes
    {
      id:                 id,
      ticket_id:          ticket_id,
      ticket_number:      ticket&.number,
      user_id:            user_id,
      is_active:          is_active,
      started_at:         started_at,
      paused_at:          paused_at,
      resumed_at:         resumed_at,
      ended_at:           ended_at,
      total_seconds:      total_seconds || 0,
      # Base que o player usa para o cronômetro: inclui as passagens anteriores
      # deste usuário pelo ticket, sem o segmento em curso.
      ticket_total_seconds: ticket_total_seconds,
      total_time_seconds: total_time_seconds,
      current_state:      current_state,
      updated_at:         updated_at
    }
  end

  private

  # Fecha o intervalo em aberto somando ao acumulador. `resumed_at` só existe
  # depois de uma retomada; na primeira vez o intervalo começa em started_at.
  def accumulate_elapsed
    elapsed = Time.zone.now - (resumed_at || started_at)
    self.total_seconds = (total_seconds || 0) + elapsed.to_i
  end

  def broadcast_state_change
    return if Setting.get('import_mode')

    # Broadcast to all sessions of this user
    message = {
      event: 'TicketTimeTracking:stateChange',
      data:  notify_clients_data_attributes
    }
    PushMessages.send_to(user_id, message)

    broadcast_to_ticket_watchers
  end

  # Avisa quem mais está com o ticket aberto, para o estado do player ficar em
  # sincronia entre agentes.
  #
  # Entregue usuário a usuário, e não por broadcast: `Sessions.broadcast` com
  # 'authenticated' alcança TODA sessão logada, cliente inclusive — o payload traz
  # ticket, agente e tempo, então um cliente ficaria sabendo qual atendente está
  # em qual ticket e há quanto tempo. Aqui vai só para quem tem acesso de leitura
  # ao grupo do ticket.
  #
  # Ver notify_clients_data_attributes para a distinção entre total_seconds e
  # total_time_seconds.
  def broadcast_to_ticket_watchers
    message = {
      event: 'Ticket:timeTrackingChange',
      data:  {
        ticket_id:          ticket_id,
        user_id:            user_id,
        current_state:      current_state,
        total_seconds:      total_seconds || 0,
        total_time_seconds: total_time_seconds,
        updated_at:         updated_at
      }
    }

    recipient_ids.each { |id| PushMessages.send_to(id, message) }
  end

  def recipient_ids
    group_id = ticket&.group_id
    return [user_id].compact if group_id.blank?

    (User.group_access_ids(group_id, 'read') + [user_id]).compact.uniq
  rescue => e
    # Uma falha ao resolver destinatários não pode impedir a gravação; no pior
    # caso o próprio usuário deixa de ver a atualização em outra aba.
    Rails.logger.error "Could not resolve time tracking broadcast recipients for ticket #{ticket_id}: #{e.message}"
    [user_id].compact
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





