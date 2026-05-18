# frozen_string_literal: true

# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
#
# Garante que o campo equipe exista como coluna física e como ObjectManager::Attribute.
#
# Problema: migration 20260119150000 criou o ObjectManager com to_create: false
# (sem criar coluna), mas a coluna física nunca foi adicionada ao banco.

class AddPauseControlObjectManagerAttributes < ActiveRecord::Migration[7.2]
  def up
    return if !Setting.exists?(name: 'system_init_done')

    UserInfo.current_user_id = 1

    fix_equipe_column
  end

  def down; end

  private

  def fix_equipe_column
    unless column_exists?(:users, :equipe)
      add_column :users, :equipe, :string, limit: 255, null: true
      add_index  :users, :equipe
    end

    attr = ObjectManager::Attribute.find_by(
      object_lookup_id: ObjectLookup.by_name('User'),
      name:             'equipe',
    )
    return if attr.blank?

    attr.update!(
      display:     'Equipe',
      data_option: attr.data_option.merge(
        'type'       => 'text',
        'maxlength'  => 255,
        'null'       => true,
        'item_class' => 'formGroup--halfSize',
      ),
      editable:    true,
      to_create:   false,
      to_migrate:  false,
      screens:     {
        'signup'          => {},
        'invite_agent'    => {},
        'invite_customer' => {},
        'edit'            => { '-all-' => { null: true } },
        'view'            => { '-all-' => { shown: true } },
      },
    )
  end
end
