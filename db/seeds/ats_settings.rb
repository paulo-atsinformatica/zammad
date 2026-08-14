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
