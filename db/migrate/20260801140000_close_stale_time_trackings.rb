# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: controle de tempo de atendimento.

class CloseStaleTimeTrackings < ActiveRecord::Migration[8.0]
  # Nada encerrava uma contagem esquecida: um agente que inicia e fecha o
  # navegador deixava o cronômetro correndo noites e fins de semana inteiros, e
  # esse tempo entrava no relatório como atendimento.
  def up
    return if !Setting.exists?(name: 'system_init_done')

    add_setting
    add_scheduler
  end

  def down
    Scheduler.find_by(method: 'TicketTimeTracking.close_stale')&.destroy
    Setting.find_by(name: 'ticket_time_tracking_max_running_hours')&.destroy
  end

  private

  def add_setting
    Setting.create_if_not_exists(
      title:       __('Maximum running time of a ticket time tracking'),
      name:        'ticket_time_tracking_max_running_hours',
      area:        'Ticket::Base',
      description: __('Hours after which a time tracking left running is closed automatically. Set to 0 to disable.'),
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'ticket_time_tracking_max_running_hours',
            tag:     'input',
          },
        ],
      },
      state:       TicketTimeTracking::DEFAULT_MAX_RUNNING_HOURS,
      preferences: {
        permission: ['admin.ticket'],
      },
      frontend:    false
    )
  end

  # De hora em hora: o corte é em horas, então varrer com mais frequência não
  # muda o resultado e só gasta ciclo.
  def add_scheduler
    Scheduler.create_or_update(
      name:          __('Close ticket time trackings left running.'),
      method:        'TicketTimeTracking.close_stale',
      period:        1.hour,
      prio:          2,
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
    )
  end
end
