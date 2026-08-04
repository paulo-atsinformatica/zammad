# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AddTimeTrackingFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :enable_pause_control, :boolean, null: false, default: false
    add_column :users, :enable_ticket_time_tracking, :boolean, null: false, default: false
    add_column :users, :current_state, :string, limit: 20, null: true, default: 'offline'
    add_reference :users, :current_pause, null: true, foreign_key: { to_table: :user_pauses }
    add_reference :users, :current_active_ticket, null: true, foreign_key: { to_table: :tickets }

    add_index :users, [:current_state]
  end
end


