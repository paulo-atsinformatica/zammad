# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class CreateUserPauses < ActiveRecord::Migration[7.2]
  def change
    create_table :user_pauses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :pause_type, null: true, foreign_key: true
      t.datetime :started_at, limit: 3, null: false
      t.datetime :ended_at, limit: 3, null: true
      t.integer :time_limit, null: false, comment: 'Time limit in minutes'
      t.text :delay_reason, null: true, comment: 'Reason for exceeding time limit'
      t.integer :updated_by_id, null: false
      t.integer :created_by_id, null: false
      t.timestamps limit: 3, null: false
    end

    add_index :user_pauses, [:user_id, :ended_at]
    add_index :user_pauses, [:started_at]
    add_foreign_key :user_pauses, :users, column: :created_by_id
    add_foreign_key :user_pauses, :users, column: :updated_by_id
  end
end


