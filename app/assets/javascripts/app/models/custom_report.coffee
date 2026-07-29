# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: relatório personalizado.

class App.CustomReport extends App.Model
  @configure 'CustomReport', 'name', 'object', 'visibility', 'condition', 'columns', 'active'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/custom_reports'

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
    {
      name:    'visibility',
      display: __('Visible for'),
      tag:     'select',
      options:
        personal: __('Only me')
        group:    __('Members of selected groups')
        global:   __('Everyone')
      default: 'personal'
      null:    false
      note:    __('This only controls who sees this report. The data is always limited to what the person generating it is allowed to see.')
    },
    {
      name:     'group_ids',
      display:  __('Groups'),
      tag:      'column_select',
      relation: 'Group',
      null:     true,
      note:     __('Only used when the report is visible for members of selected groups.'),
    },
    # tag: 'ticket_selector' reaproveita o mesmo editor de condições usado por
    # Overviews, Triggers e Agendamentos, com todos os campos de ticket,
    # organização, usuário e grupo.
    { name: 'condition',  display: __('Filter'), tag: 'ticket_selector', null: true },
    { name: 'active',     display: __('Active'), tag: 'active', default: true },
  ]

  visibilityName: ->
    switch @visibility
      when 'global'   then App.i18n.translateInline('Everyone')
      when 'group'    then App.i18n.translateInline('Groups')
      when 'personal' then App.i18n.translateInline('Only me')
      else @visibility

  filterDescription: ->
    return App.i18n.translateInline('No filter') if _.isEmpty(@condition)

    App.UiElement.ticket_selector.humanText(@condition)?.join(', ')
