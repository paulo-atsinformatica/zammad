# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AddCustomerTicketUpdateSettings < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    # Defaults keep the previous behaviour (customers may modify their own
    # tickets), so upgrading does not silently lock anyone out.
    Setting.create_if_not_exists(
      title:       'Ticket modification by customers',
      name:        'customer_ticket_update',
      area:        'CustomerWeb::Base',
      description: 'Defines if a customer can modify their tickets (change attributes, rename them or add articles). If disabled, customers get read-only access to tickets.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'customer_ticket_update',
            tag:     'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state:       true,
      preferences: {
        authentication: true,
        permission:     ['admin.channel_web'],
      },
      frontend:    true
    )

    Setting.create_if_not_exists(
      title:       'Group selection for Ticket modification',
      name:        'customer_ticket_update_group_ids',
      area:        'CustomerWeb::Base',
      description: 'Defines groups in which a customer can modify their tickets. No selection means all groups are available.',
      options:     {
        form: [
          {
            display:  '',
            null:     true,
            name:     'group_ids',
            tag:      'tree_select',
            multiple: true,
            relation: 'Group',
          },
        ],
      },
      state:       nil,
      preferences: {
        authentication: true,
        permission:     ['admin.channel_web'],
      },
      frontend:    true
    )
  end
end
