# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: permissões do relatório personalizado.

class AddCustomReportPermissions < ActiveRecord::Migration[8.0]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    create_permissions

    # Agente e Admin podem usar e salvar relatório pessoal. Salvar em nível de
    # grupo ou global é concedido só ao Admin por padrão, para não expor
    # relatório de todo mundo por acidente — ajustável em Funções.
    Role.find_by(name: 'Agent')&.permission_grant('report.custom')

    admin_role = Role.find_by(name: 'Admin')
    return if !admin_role

    %w[report.custom report.custom.group report.custom.global].each do |name|
      admin_role.permission_grant(name)
    end
  end

  def down
    Permission.where(name: %w[report.custom report.custom.group report.custom.global]).destroy_all
  end

  private

  def create_permissions
    Permission.create_if_not_exists(
      name:        'report.custom',
      label:       __('Custom Report'),
      description: __('Create and generate custom reports. Results always respect the group and object permissions of the user generating them.'),
      preferences: { prio: 1610 },
      active:      true,
    )

    Permission.create_if_not_exists(
      name:        'report.custom.group',
      label:       __('Share Custom Report With Group'),
      description: __('Save custom reports visible to the members of a group.'),
      preferences: { prio: 1611 },
      active:      true,
    )

    Permission.create_if_not_exists(
      name:        'report.custom.global',
      label:       __('Share Custom Report Globally'),
      description: __('Save custom reports visible to every user who may use custom reports.'),
      preferences: { prio: 1612 },
      active:      true,
    )
  end
end
