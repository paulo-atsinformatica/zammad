# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: setting de limite e limpeza dos relatórios personalizados.

class AddCustomReportSettingsAndScheduler < ActiveRecord::Migration[8.0]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_setting
    add_scheduler
  end

  def down
    Setting.find_by(name: 'custom_report_max_rows')&.destroy
    Scheduler.find_by(method: 'CustomReportRun.cleanup')&.destroy
  end

  private

  def add_setting
    Setting.create_if_not_exists(
      title:       __('Custom report row limit'),
      name:        'custom_report_max_rows',
      area:        'CustomReport::Base',
      description: __('Maximum number of rows a single custom report may generate. Protects the server from an unfiltered report scanning the whole database.'),
      options:     {
        form: [
          {
            display: '',
            null:    false,
            name:    'custom_report_max_rows',
            tag:     'input',
          },
        ],
      },
      state:       500_000,
      preferences: {
        permission: ['admin.report'],
      },
      frontend:    true
    )
  end

  def add_scheduler
    Scheduler.create_or_update(
      name:          __('Delete expired custom report files.'),
      method:        'CustomReportRun.cleanup',
      period:        1.day,
      prio:          2,
      active:        true,
      updated_by_id: 1,
      created_by_id: 1,
    )
  end
end
