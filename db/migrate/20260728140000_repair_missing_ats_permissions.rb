# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: repara permissões ausentes.

# As permissões das funcionalidades ATS eram criadas apenas por migrations que
# começam com `return if !Setting.exists?(name: 'system_init_done')`. Numa
# instalação nova esse setting ainda não existe quando as migrations rodam, então
# elas saíam pelo guard — e o `db/seeds/permissions.rb` (que roda depois) não as
# continha. Resultado: instância recém-criada ficava sem `ticket.time_tracking`,
# `user.pause_control` etc, e as funcionalidades simplesmente não apareciam na
# interface (o player de tempo não era renderizado, o item de menu do relatório
# personalizado era filtrado por permissão).
#
# O seed já foi corrigido para instalações novas, mas as migrations originais
# constam como executadas e não rodam de novo. Esta migration existe para
# consertar as instâncias que ficaram nesse estado.
#
# Não tem guard de system_init_done de propósito, e é idempotente: em instalação
# nova o seed cria as mesmas permissões e `create_if_not_exists` apenas as
# encontra.
class RepairMissingAtsPermissions < ActiveRecord::Migration[8.0]
  PERMISSIONS = [
    {
      name:        'ticket.time_tracking',
      label:       __('Ticket Time Tracking'),
      description: __('Track time spent on tickets.'),
      prio:        1565,
      roles:       %w[Admin Agent],
    },
    {
      name:        'user',
      label:       __('User features'),
      description: __('User-specific features and controls.'),
      prio:        3000,
      roles:       [],
    },
    {
      name:        'user.pause_control',
      label:       __('Pause Control'),
      description: __('Allow user to manage pause states (online, offline, pause).'),
      prio:        3010,
      roles:       %w[Agent],
    },
    {
      name:        'user.ticket_time_tracking',
      label:       __('Ticket Time Tracking'),
      description: __('Allow automatic time tracking on tickets.'),
      prio:        3020,
      roles:       %w[Agent],
    },
    {
      name:        'report.custom',
      label:       __('Custom Report'),
      description: __('Create and generate custom reports. Results always respect the group and object permissions of the user generating them.'),
      prio:        1544,
      roles:       %w[Admin Agent],
    },
    {
      name:        'report.custom.group',
      label:       __('Share Custom Report With Group'),
      description: __('Save custom reports visible to the members of a group.'),
      prio:        1545,
      roles:       %w[Admin],
    },
    {
      name:        'report.custom.global',
      label:       __('Share Custom Report Globally'),
      description: __('Save custom reports visible to every user who may use custom reports.'),
      prio:        1546,
      roles:       %w[Admin],
    },
  ].freeze

  def up
    PERMISSIONS.each do |attributes|
      # Só concede aos papéis quando a permissão foi criada agora. Se ela já
      # existia, as concessões podem ter sido ajustadas de propósito por um
      # admin e não devem ser mexidas.
      next if Permission.exists?(name: attributes[:name])

      Permission.create_if_not_exists(
        name:        attributes[:name],
        label:       attributes[:label],
        description: attributes[:description],
        preferences: { prio: attributes[:prio] },
        active:      true,
      )

      attributes[:roles].each do |role_name|
        Role.find_by(name: role_name)&.permission_grant(attributes[:name])
      end
    end
  end

  def down
    # Não remove nada: as permissões podem estar em uso, e removê-las
    # esconderia funcionalidades em vez de reverter um estado ruim.
  end
end
