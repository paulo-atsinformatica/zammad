# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AddPauseTypePermission < ActiveRecord::Migration[7.2]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    permission = Permission.create_if_not_exists(
      name:        'admin.pause_type',
      label:       __('Pause Types'),
      description: __('Manage pause types of your system.'),
      preferences: { prio: 1096 },
      active:      true,
    )

    # Grant permission to Admin role
    admin_role = Role.find_by(name: 'Admin')
    if admin_role && permission
      admin_role.permission_grant('admin.pause_type')
    end
  end
end

