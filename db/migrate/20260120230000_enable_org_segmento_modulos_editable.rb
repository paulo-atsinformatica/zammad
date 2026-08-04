# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class EnableOrgSegmentoModulosEditable < ActiveRecord::Migration[7.2]
  def up
    return if !Setting.exists?(name: 'system_init_done')

    UserInfo.current_user_id = 1

    enable_editable('segmento', multiple: false, default_value: nil)
    enable_editable('modulos', multiple: true, default_value: [])
  end

  def down
    UserInfo.current_user_id = 1

    disable_editable('segmento')
    disable_editable('modulos')
  end

  private

  def find_attribute(name)
    object_lookup_id = ObjectLookup.by_name('Organization')
    ObjectManager::Attribute.find_by(object_lookup_id: object_lookup_id, name: name)
  end

  def enable_editable(name, multiple:, default_value:)
    attribute = find_attribute(name)
    return if attribute.blank?

    options = (attribute.data_option || {}).dup
    options['options'] ||= []
    options['nulloption'] = true if options['nulloption'].nil?
    options['multiple'] = multiple
    options['default'] = default_value if options['default'].nil?
    options['translate'] = false if options['translate'].nil?

    attribute.update!(editable: true, data_option: options)
  end

  def disable_editable(name)
    attribute = find_attribute(name)
    return if attribute.blank?

    attribute.update!(editable: false)
  end
end

