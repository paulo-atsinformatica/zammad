# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class CreateTicketTimeTrackings < ActiveRecord::Migration[7.2]
  def change
    create_table :ticket_time_trackings do |t|
      t.references :ticket, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :started_at, limit: 3, null: false
      t.datetime :paused_at, limit: 3, null: true
      t.datetime :resumed_at, limit: 3, null: true
      t.datetime :ended_at, limit: 3, null: true
      t.integer :total_seconds, null: false, default: 0, comment: 'Total tracked time in seconds'
      t.boolean :is_active, null: false, default: true
      t.integer :updated_by_id, null: false
      t.integer :created_by_id, null: false
      t.timestamps limit: 3, null: false
    end

    add_index :ticket_time_trackings, [:ticket_id, :is_active]
    add_index :ticket_time_trackings, [:user_id, :is_active]
    add_index :ticket_time_trackings, [:started_at]
    add_foreign_key :ticket_time_trackings, :users, column: :created_by_id
    add_foreign_key :ticket_time_trackings, :users, column: :updated_by_id

    # Ensure only one active tracking per user (partial unique index)
    execute <<-SQL
      CREATE UNIQUE INDEX index_ticket_time_trackings_on_user_id_when_active
      ON ticket_time_trackings (user_id)
      WHERE is_active = true;
    SQL
  end
end

