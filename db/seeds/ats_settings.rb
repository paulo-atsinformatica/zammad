# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: settings nativos do Zammad que o fork liga por padrão.
# Separado de db/seeds/settings.rb de propósito — aquele arquivo é 100% stock
# e mexer nele aumentaria o risco de conflito num sync com o upstream.
#
# Roda depois de settings.rb (ver a lista ordenada em db/seeds.rb), então os
# settings já existem aqui.

# Mostra a quantidade de tickets ao lado do nome de cada agrupamento na visão
# geral (ex.: "Débora Carvalho (4)"). A feature é nativa
# (App.ControllerTable#renderTableGroupByRow), mas vem desligada de fábrica e é
# quase impossível de achar no admin: o título do setting é 'Open ticket
# indicator', que não tem nada a ver com o que ele faz.
Setting.set('ui_table_group_by_show_count', true)

# Som do aviso de fim de pausa. A antecedência é por tipo de pausa
# (pause_types.warning_minutes); este setting só liga/desliga o som, para quem
# trabalha em sala compartilhada poder deixar só o aviso visual.
Setting.create_if_not_exists(
  title:       __('Pause warning sound'),
  name:        'pause_control_warning_sound',
  area:        'UI::Base',
  description: __('Play a sound when a pause is about to reach its time limit.'),
  options:     {
    form: [
      {
        display:   '',
        null:      true,
        name:      'pause_control_warning_sound',
        tag:       'boolean',
        translate: true,
        options:   {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       true,
  preferences: {
    permission: ['admin.ui'],
  },
  frontend:    true
)
