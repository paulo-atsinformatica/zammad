# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: relatório personalizado.

# A tela de visualização do relatório usa o bundle da Desktop View, servida em
# /report (ver config/routes/custom_report_ui.rb), a partir de
# app/frontend/apps/desktop/pages/custom-report. Aqui ficam apenas o item de
# menu e um redirecionamento para os links antigos.
REPORT_URL = '/report/custom-reports'

# Rota legada mantida só para links já existentes (notificação de relatório
# pronto, favoritos). Redireciona em vez de renderizar: a tela antiga foi
# substituída pela da Desktop View.
class App.ReportCustom extends App.ControllerAppContent
  @requiredPermission: ['report.custom']

  constructor: ->
    super
    window.location.href = REPORT_URL

App.Config.set('report/custom', App.ReportCustom, 'Routes')

# Item no menu de Relatórios.
#
# O target é uma URL de verdade, não uma rota hash do SPA legado. Abrir uma
# segunda instância do SPA legado dispara o evento `session_takeover`
# (app/assets/javascripts/app/controllers/_plugin/session_taken_over.coffee),
# que derruba a aba original. A Desktop View não participa desse mecanismo,
# então o usuário segue trabalhando na aba de origem.
#
# `external: true` é o mecanismo do próprio Zammad para renderizar
# target="_blank" (ver views/navigation/personal.jst.eco).
# `translate: true` é obrigatório: views/navigation/personal.jst.eco só passa o
# nome por @T() quando a flag está presente, senão renderiza o texto cru — era por
# isso que o item aparecia como "Custom Report" mesmo com a tradução no catálogo.
# Os outros itens ATS não precisam porque o nome deles já é literal em português.
App.Config.set('CustomReport', {
  prio: 100,
  name: __('Custom Report'),
  parent: '#report',
  target: REPORT_URL,
  external: true,
  translate: true,
  permission: ['report.custom']
}, 'NavBarRight')
