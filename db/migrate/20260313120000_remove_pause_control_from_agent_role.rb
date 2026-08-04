# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Remove a permissão user.pause_control do role genérico "Agent".
#
# Motivação:
#   A migração 20251227130000 adicionou user.pause_control ao role Agent por
#   conveniência. Isso faz com que TODOS os agentes apareçam no relatório de
#   Indicadores de Pausa, independente de terem o controle de pausas configurado.
#
#   O relatório deve mostrar apenas usuários cujo role ESPECÍFICO tenha a permissão
#   user.pause_control habilitada (ex: role "Suporte"). A query `eligible_role_ids`
#   já faz isso corretamente — o único problema é o ruído introduzido pelo Agent role.
#
# O que esta migração faz:
#   Remove user.pause_control do role "Agent" apenas.
#   Roles customizados (ex: "Suporte") que têm a permissão continuam funcionando.
#
class RemovePauseControlFromAgentRole < ActiveRecord::Migration[7.2]
  PERMISSION_NAME = 'user.pause_control'

  def up
    permission = Permission.find_by(name: PERMISSION_NAME)
    return unless permission

    agent_role = Role.find_by(name: 'Agent')
    return unless agent_role

    if agent_role.permissions.include?(permission)
      agent_role.permissions.delete(permission)
      Rails.logger.info "[RemovePauseControlFromAgentRole] Removed '#{PERMISSION_NAME}' from Agent role"
    end
  end

  def down
    permission = Permission.find_by(name: PERMISSION_NAME)
    return unless permission

    agent_role = Role.find_by(name: 'Agent')
    return unless agent_role

    unless agent_role.permissions.include?(permission)
      agent_role.permissions << permission
    end
  end
end
