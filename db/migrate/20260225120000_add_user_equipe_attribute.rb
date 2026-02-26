# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AddUserEquipeAttribute < ActiveRecord::Migration[7.0]
  def up
    return if !Setting.exists?(name: 'system_init_done')

    existing = ObjectManager::Attribute.find_by(
      object_lookup_id: ObjectLookup.by_name('User'),
      name:             'equipe'
    )
    return if existing.present?

    UserInfo.current_user_id = 1

    ObjectManager::Attribute.add(
      force:       true,
      object:      'User',
      name:        'equipe',
      display:     'Equipe',
      data_type:   'input',
      data_option: {
        type:       'text',
        maxlength:  255,
        null:       true,
        item_class: 'formGroup--halfSize',
      },
      editable:    true,
      active:      true,
      screens:     {
        signup:          {},
        invite_agent:    {},
        invite_customer: {},
        edit:            {
          '-all-' => {
            null: true,
          },
        },
        view:            {
          '-all-' => {
            shown: true,
          },
        },
      },
      to_create:   true,
      to_migrate:  true,
      to_delete:   false,
      position:    1600,
      created_by_id: 1,
      updated_by_id: 1,
    )

    ObjectManager::Attribute.migration_execute(false)
  end

  def down
    return if !Setting.exists?(name: 'system_init_done')

    attr = ObjectManager::Attribute.find_by(
      object_lookup_id: ObjectLookup.by_name('User'),
      name:             'equipe'
    )
    return if attr.blank?

    attr.to_delete = true
    attr.save!
    ObjectManager::Attribute.migration_execute(false)
  end
end
