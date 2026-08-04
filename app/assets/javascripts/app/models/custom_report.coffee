# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: relatório personalizado.

class App.CustomReport extends App.Model
  # Todo atributo que o formulário envia precisa estar aqui: o Spine monta o
  # payload de gravação a partir desta lista, e o que faltar é descartado em
  # silêncio.
  @configure 'CustomReport', 'name', 'object', 'group_ids', 'user_ids', 'condition', 'columns', 'enabled_filters', 'group_by', 'aggregations', 'aggregation_attributes', 'active', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/custom_reports'
  @configure_delete = true

  @configure_attributes = [
    { name: 'name',       display: __('Name'),   tag: 'input',  type: 'text', limit: 250, null: false },
    {
      name:    'object',
      display: __('Report about'),
      tag:     'select',
      # Fase 1 gera apenas Ticket. Usuário e Organização entram na fase 2, e
      # ficam de fora daqui até lá para não oferecer algo que não roda.
      options: { Ticket: __('Tickets') },
      default: 'Ticket',
      null:    false,
    },
    # Compartilhamento no mesmo modelo da Visão Geral: grupos e/ou usuários.
    # Quem criou sempre enxerga o próprio relatório, então deixar os dois vazios
    # equivale ao antigo "pessoal".
    {
      name:     'group_ids',
      display:  __('Available for the following groups'),
      tag:      'column_select',
      relation: 'Group',
      null:     true,
      note:     __('This only controls who sees this report. The data is always limited to what the person generating it is allowed to see.'),
    },
    {
      name:     'user_ids',
      display:  __('Also available for the following users'),
      tag:      'column_select',
      relation: 'User',
      sortBy:   'displayName',
      null:     true,
      note:     __('Added to the groups above, not intersected with them.'),
    },
    # tag: 'ticket_selector' reaproveita o mesmo editor de condições usado por
    # Overviews, Triggers e Agendamentos, com todos os campos de ticket,
    # organização, usuário e grupo.
    { name: 'condition',  display: __('Filter'), tag: 'ticket_selector', null: true, note: __('Fixed scope of the report. Whoever opens it cannot widen this.') },
    # checkboxTicketAttributes é o mesmo componente que a Visão Geral usa para
    # escolher colunas, então a lista acompanha os atributos do ticket,
    # inclusive os customizados. Ele entrega o nome sem o sufixo _id
    # (state, não state_id); o backend normaliza.
    { name: 'columns', display: __('Columns'), tag: 'checkboxTicketAttributes', null: true, translate: true, note: __('Columns shown in the grid and in the exported file.') },
    # Atributos que a tela de visualização deixa o usuário filtrar na hora.
    { name: 'enabled_filters', display: __('Filters available when viewing'), tag: 'checkboxTicketAttributes', null: true, translate: true, note: __('Attributes the viewer may filter by. Leave empty to offer no filters.') },
    # Totalizadores. Agrupa por estes atributos e calcula as funções escolhidas
    # para cada combinação, mais uma linha de total geral.
    { name: 'group_by', display: __('Group totals by'), tag: 'checkboxTicketAttributes', null: true, translate: true, note: __('Leave empty for no totals section.') },
    {
      name:    'aggregations',
      display: __('Totals to calculate'),
      tag:     'select',
      multiple: true,
      null:    true,
      options:
        count: __('Count')
        sum:   __('Sum')
        avg:   __('Average')
        min:   __('Minimum')
        max:   __('Maximum')
      note: __('Count needs no field. The others apply to the fields chosen below.')
    },
    # Separado das funções para o formulário não precisar de um editor de pares
    # função+campo. O backend faz o produto dos dois (ver CustomReport::Summary).
    { name: 'aggregation_attributes', display: __('Fields to total'), tag: 'checkboxTicketAttributes', null: true, translate: true, note: __('Sum and average only apply to numeric fields.') },
    { name: 'active',     display: __('Active'), tag: 'active', default: true },
  ]

  # Colunas do grid de Gerenciar > Relatórios Personalizados. Sem isto o
  # App.ControllerTable levanta "overviewAttributes needed" e a lista fica vazia.
  @configure_overview = [
    'name',
    'object',
    'group_ids',
  ]

  filterDescription: ->
    return App.i18n.translateInline('No filter') if _.isEmpty(@condition)

    App.UiElement.ticket_selector.humanText(@condition)?.join(', ')
