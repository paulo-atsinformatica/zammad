# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AddTicketTimeTrackingPermission < ActiveRecord::Migration[7.2]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')
    return if Permission.find_by(name: 'ticket.time_tracking')

    permission = Permission.create_if_not_exists(
      name:        'ticket.time_tracking',
      label:       __('Ticket Time Tracking'),
      description: __('Track time spent on tickets.'),
      preferences: { prio: 1565 },
      active:      true,
    )

    # Grant permission to Admin and Agent roles
    admin_role = Role.find_by(name: 'Admin')
    if admin_role && permission
      admin_role.permission_grant('ticket.time_tracking')
    end

    agent_role = Role.find_by(name: 'Agent')
    if agent_role && permission
      agent_role.permission_grant('ticket.time_tracking')
    end
  end

  def down
    permission = Permission.find_by(name: 'ticket.time_tracking')
    permission&.destroy
  end
end

