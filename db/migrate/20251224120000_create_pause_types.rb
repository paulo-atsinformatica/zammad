# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class CreatePauseTypes < ActiveRecord::Migration[7.2]
  def change
    create_table :pause_types do |t|
      t.string :name, limit: 200, null: false
      t.integer :time_limit, null: false, comment: 'Time limit in minutes'
      t.string :color, limit: 7, null: true, comment: 'Hex color code'
      t.boolean :active, null: false, default: true
      t.integer :updated_by_id, null: false
      t.integer :created_by_id, null: false
      t.timestamps limit: 3, null: false
    end

    add_index :pause_types, [:name], unique: true
    add_index :pause_types, [:active]
    add_foreign_key :pause_types, :users, column: :created_by_id
    add_foreign_key :pause_types, :users, column: :updated_by_id
  end
end




