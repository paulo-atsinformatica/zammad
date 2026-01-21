# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AddUserDefaultFields < ActiveRecord::Migration[7.2]
  def up
    return if !Setting.exists?(name: 'system_init_done')

    UserInfo.current_user_id = 1

    add_user_field(
      name:        'cargo',
      display:     'Cargo',
      data_type:   'input',
      data_option: {
        type:      'text',
        maxlength: 255,
        null:      true,
      },
      position:    1808
    )

    add_user_field(
      name:        'superiorhierarquico',
      display:     'Superior hierárquico',
      data_type:   'input',
      data_option: {
        type:      'text',
        maxlength: 255,
        null:      true,
      },
      position:    1809
    )

    add_user_field(
      name:        'equipe',
      display:     'Equipe',
      data_type:   'input',
      data_option: {
        type:      'text',
        maxlength: 255,
        null:      true,
      },
      position:    1818
    )

    add_user_field(
      name:        'observacao',
      display:     'Observação',
      data_type:   'textarea',
      data_option: {
        type:      'text',
        maxlength: 10_000,
        null:      true,
        rows:      7,
      },
      position:    1819
    )

    add_user_field(
      name:        'bloqueado',
      display:     'Bloqueado',
      data_type:   'boolean',
      data_option: {
        null:      true,
        default:   false,
        options:   {
          false: 'Não',
          true:  'Sim',
        },
        translate: false,
      },
      position:    1820
    )
  end

  def down
    UserInfo.current_user_id = 1

    ObjectManager::Attribute.remove(object: 'User', name: 'cargo', force: true)
    ObjectManager::Attribute.remove(object: 'User', name: 'superiorhierarquico', force: true)
    ObjectManager::Attribute.remove(object: 'User', name: 'equipe', force: true)
    ObjectManager::Attribute.remove(object: 'User', name: 'observacao', force: true)
    ObjectManager::Attribute.remove(object: 'User', name: 'bloqueado', force: true)
  end

  private

  def add_user_field(name:, display:, data_type:, data_option:, position:)
    ObjectManager::Attribute.add(
      force:         true,
      object:        'User',
      name:          name,
      display:       display,
      data_type:     data_type,
      data_option:   data_option,
      editable:      false,
      active:        true,
      screens:       {
        signup:          { '-all-' => { null: true } },
        invite_agent:    { '-all-' => { null: true } },
        invite_customer: { '-all-' => { null: true } },
        edit:            { '-all-' => { null: true } },
        view:            { '-all-' => { shown: true } },
      },
      to_create:     false,
      to_migrate:    false,
      to_delete:     false,
      position:      position,
      created_by_id: 1,
      updated_by_id: 1,
    )
  end
end
