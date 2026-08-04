# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class CreateUserPauseSessions < ActiveRecord::Migration[7.2]
  def change
    create_table :user_pause_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.datetime :started_at, null: false
      t.datetime :ended_at
      t.bigint :created_by_id
      t.bigint :updated_by_id
      t.timestamps
    end

    add_index :user_pause_sessions, %i[user_id ended_at]
  end
end
