# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: permissão da tela de configuração do relatório personalizado.

# Criar e editar modelos de relatório passou a ser tarefa de configuração
# (Gerenciar), separada da tela de visualização, que só visualiza e exporta.
#
# Sem guard de system_init_done de propósito: as migrations com esse guard não
# rodam em instalação nova, e foi assim que as permissões ATS deixaram de existir
# em instâncias recém-criadas (ver RepairMissingAtsPermissions). O seed também
# contém esta permissão, e create_if_not_exists torna as duas vias idempotentes.
class AddCustomReportAdminPermission < ActiveRecord::Migration[8.0]
  def up
    return if Permission.exists?(name: 'admin.custom_report')

    Permission.create_if_not_exists(
      name:        'admin.custom_report',
      label:       __('Custom Reports'),
      description: __('Manage custom reports of your system.'),
      preferences: { prio: 1161 },
      active:      true,
    )

    Role.find_by(name: 'Admin')&.permission_grant('admin.custom_report')
  end

  def down
    # Não remove: esconderia a tela de configuração em vez de reverter um estado
    # ruim, e a permissão pode já estar atribuída a papéis customizados.
  end
end
