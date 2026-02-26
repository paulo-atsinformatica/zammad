# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AddReportGranularPermissions < ActiveRecord::Migration[7.2]
  def up
    Permission.create_if_not_exists(
      name:        'report.pause_indicators',
      label:       __('Pause Indicators'),
      description: __('Access to the Pause Indicators report.'),
      preferences: { prio: 1541 }
    )

    Permission.create_if_not_exists(
      name:        'report.user_pauses',
      label:       __('User Pauses Report'),
      description: __('Access to the User Pauses report.'),
      preferences: { prio: 1542 }
    )

    Permission.create_if_not_exists(
      name:        'report.ticket_time_trackings',
      label:       __('Ticket Time Trackings Report'),
      description: __('Access to the Ticket Time Trackings report.'),
      preferences: { prio: 1543 }
    )
  end

  def down
    Permission.find_by(name: 'report.pause_indicators')&.destroy
    Permission.find_by(name: 'report.user_pauses')&.destroy
    Permission.find_by(name: 'report.ticket_time_trackings')&.destroy
  end
end
