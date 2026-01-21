# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class RemovePauseControlFieldsFromUsers < ActiveRecord::Migration[7.2]
  def change
    remove_column :users, :enable_pause_control, :boolean if column_exists?(:users, :enable_pause_control)
    remove_column :users, :enable_ticket_time_tracking, :boolean if column_exists?(:users, :enable_ticket_time_tracking)
  end
end
