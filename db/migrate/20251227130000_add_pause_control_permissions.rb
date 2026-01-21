# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AddPauseControlPermissions < ActiveRecord::Migration[7.2]
  def up
    # Create parent permission for user features
    Permission.create_if_not_exists(
      name:        'user',
      label:       __('User features'),
      description: __('User-specific features and controls.'),
      preferences: { prio: 3000 }
    )

    # Create pause control permission
    Permission.create_if_not_exists(
      name:        'user.pause_control',
      label:       __('Pause Control'),
      description: __('Allow user to manage pause states (online, offline, pause).'),
      preferences: { prio: 3010 }
    )

    # Create ticket time tracking permission
    Permission.create_if_not_exists(
      name:        'user.ticket_time_tracking',
      label:       __('Ticket Time Tracking'),
      description: __('Allow automatic time tracking on tickets.'),
      preferences: { prio: 3020 }
    )

    # Optionally add permission to Agent role by default
    agent_role = Role.find_by(name: 'Agent')
    if agent_role
      pause_control_permission = Permission.find_by(name: 'user.pause_control')
      time_tracking_permission = Permission.find_by(name: 'user.ticket_time_tracking')

      agent_role.permissions << pause_control_permission if pause_control_permission && !agent_role.permissions.include?(pause_control_permission)
      agent_role.permissions << time_tracking_permission if time_tracking_permission && !agent_role.permissions.include?(time_tracking_permission)
    end
  end

  def down
    Permission.find_by(name: 'user.ticket_time_tracking')&.destroy
    Permission.find_by(name: 'user.pause_control')&.destroy
    # Keep parent 'user' permission as it might be used by other features
  end
end
