# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class App.ReportPauseIndicators extends App.ControllerAppContent
  @requiredPermission: ['report', 'report.pause_indicators']

  constructor: ->
    super
    @title __('Indicadores de Pausa')
    @navupdate '#report/pause_indicators'
    @pollTimer = null
    @durationTimer = null
    @agents = []
    @teams = []
    @selectedUserIds = []
    @selectedEquipes = []
    @restoreSelectedFromStorage()
    # Atualização em tempo real: quando alguém alterar status (login/logout/pausa), o servidor envia este evento via WebSocket
    @controllerBind('pause_indicators:changed', => @loadReport())
    @render()

  restoreSelectedFromStorage: ->
    try
      stored = sessionStorage.getItem('report/pause_indicators/colaboradores')
      if stored
        parsed = JSON.parse(stored)
        @selectedUserIds = parsed if Array.isArray(parsed)
    catch e
      @selectedUserIds = []
    try
      stored = sessionStorage.getItem('report/pause_indicators/equipes')
      if stored
        parsed = JSON.parse(stored)
        @selectedEquipes = parsed if Array.isArray(parsed)
    catch e
      @selectedEquipes = []

  saveSelectedToStorage: ->
    try
      sessionStorage.setItem('report/pause_indicators/colaboradores', JSON.stringify(@selectedUserIds))
    catch e
      #
    try
      sessionStorage.setItem('report/pause_indicators/equipes', JSON.stringify(@selectedEquipes))
    catch e
      #

  render: ->
    @html App.view('report/pause_indicators')()
    @loadReport()
    @bindFilterEvents()
    @startPolling()
    @startDurationTimer()

  bindFilterEvents: ->
    @el.find('.js-apply-colaboradores-filter').on('click', => @applyFilters())
    @el.find('.js-clear-colaboradores-filter').on('click', => @clearFilters())

  applyFilters: ->
    values = @el.find('.js-colaboradores-select').val() or []
    @selectedUserIds = (parseInt(id, 10) for id in values)
    equipeVals = @el.find('.js-equipe-select').val() or []
    @selectedEquipes = (v for v in equipeVals when v)
    @saveSelectedToStorage()
    @loadReport()

  clearFilters: ->
    @selectedUserIds = []
    @selectedEquipes = []
    @el.find('.js-colaboradores-select').val([])
    @el.find('.js-equipe-select').val([])
    @saveSelectedToStorage()
    @loadReport()

  renderColaboradoresFilter: (agents) ->
    return if !agents || agents.length is 0
    @agents = agents
    options = ''
    for agent in agents
      safeName = App.Utils.htmlEscape(agent.name)
      selected = @selectedUserIds.indexOf(agent.id) >= 0
      options += "<option value=\"#{agent.id}\" #{if selected then 'selected' else ''}>#{safeName}</option>"
    html = """
      <select class="form-control js-colaboradores-select" multiple="multiple" size="6">
        #{options}
      </select>
    """
    @el.find('.js-colaboradores-filter').html(html)

  renderEquipeFilter: (teams) ->
    return if !teams
    @teams = teams
    if teams.length is 0
      @el.find('.js-equipe-filter').html("<span class='text-muted'>#{__('Nenhuma equipe cadastrada')}</span>")
      return
    options = ''
    for team in teams
      safe = App.Utils.htmlEscape(team)
      selected = @selectedEquipes.indexOf(team) >= 0
      options += "<option value=\"#{safe}\" #{if selected then 'selected' else ''}>#{safe}</option>"
    html = """
      <select class="form-control js-equipe-select" multiple="multiple" size="6">
        #{options}
      </select>
    """
    @el.find('.js-equipe-filter').html(html)

  loadReport: ->
    return if window.location.hash isnt '#report/pause_indicators'
    params = {}
    if @selectedUserIds.length > 0
      params.user_ids = @selectedUserIds
    if @selectedEquipes.length > 0
      params.equipes = @selectedEquipes
    @ajax(
      id:          'pause_indicators_report'
      type:        'GET'
      url:         "#{@apiPath}/reports/pause_indicators"
      data:        params
      processData: true
      success:     (data) =>
        return if window.location.hash isnt '#report/pause_indicators'
        @renderColaboradoresFilter(data.agents) if data.agents
        @renderEquipeFilter(data.teams) if data.teams?
        @renderReport(data)
        @startDurationTimer()
      error: (xhr, statusText, error) =>
        return if window.location.hash isnt '#report/pause_indicators'
        return if statusText is 'abort' or (xhr && xhr.statusText is 'abort')
        @notify(
          type:    'error'
          msg:     __('Failed to load report')
          timeout: 5000
        )
    )

  renderReport: (data) ->
    @el.find('.js-report-content').html App.view('report/pause_indicators_content')(
      data:        data
      can_control: data.can_control
    )
    @updateAllDurations()
    @bindRowActions()
    @bindDropdownPortal()

  bindDropdownPortal: ->
    # Evita que o dropdown de ações seja cortado pelo overflow do .content: move o menu para body com position fixed
    @el.off('show.bs.dropdown.pausePortal hidden.bs.dropdown.pausePortal', '.pause-indicators-actions')
    @el.on 'show.bs.dropdown.pausePortal', '.pause-indicators-actions', (e) =>
      $dropdown = $(e.target)
      $menu = $dropdown.find('.dropdown-menu').first()
      return if !$menu.length
      userId = $dropdown.closest('tr.pause-indicators-row').data('user-id')
      $dropdown.data('pause-portal-menu', $menu)
      $menu.data('pause-user-id', userId)
      $menu.appendTo(document.body)
      $menu.addClass('dropdown-menu--portal-pause')
    @el.on 'shown.bs.dropdown.pausePortal', '.pause-indicators-actions', (e) =>
      $dropdown = $(e.target)
      $menu = $dropdown.data('pause-portal-menu')
      return if !$menu?.length
      $toggle = $dropdown.find('[data-toggle="dropdown"]').first()
      return if !$toggle.length
      rect = $toggle[0].getBoundingClientRect()
      menuH = $menu.outerHeight()
      spaceBelow = window.innerHeight - rect.bottom
      # Abre acima se não cabe abaixo
      if spaceBelow < menuH + 8 && rect.top > menuH + 8
        top = rect.top - menuH - 4
      else
        top = rect.bottom + 4
      left = rect.right - $menu.outerWidth()
      $menu.css(
        position: 'fixed'
        top: "#{top}px"
        left: "#{left}px"
        zIndex: 1060
      )
    @el.on 'hidden.bs.dropdown.pausePortal', '.pause-indicators-actions', (e) =>
      $dropdown = $(e.target)
      $menu = $dropdown.data('pause-portal-menu')
      return if !$menu?.length
      $menu.appendTo($dropdown)
      $menu.removeClass('dropdown-menu--portal-pause')
      $menu.css(position: '', top: '', left: '', zIndex: '')
      $dropdown.removeData('pause-portal-menu')

  bindRowActions: ->
    table = @el.find('.table--pause-indicators')
    return if !table.length

    table.off('.pause-actions')
    $(document).off('click.pause-actions-report')

    # Delegação na tabela (menu ainda dentro da linha)
    table.on 'click.pause-actions', '.js-row-action', (e) =>
      e.preventDefault()
      e.stopPropagation()
      action = $(e.currentTarget).data('action')
      $row   = $(e.currentTarget).closest('tr.pause-indicators-row')
      userId = $row.data('user-id')
      return unless action && userId
      @rowAction(action, e, userId, $row)

    # Delegação no document (menu movido para body pelo portal)
    $(document).on 'click.pause-actions-report', '.dropdown-menu--portal-pause .js-row-action', (e) =>
      e.preventDefault()
      e.stopPropagation()
      $link  = $(e.currentTarget)
      $menu  = $link.closest('.dropdown-menu')
      userId = $menu.data('pause-user-id')
      action = $link.data('action')
      return unless action && userId
      $row   = @el.find("tr.pause-indicators-row[data-user-id='#{userId}']")
      @rowAction(action, e, userId, $row)

  rowAction: (action, event, userId, $row) ->
    return if !userId

    $link = $(event.currentTarget)

    # 1. Fecha dropdown imediatamente sem esperar resposta da rede
    @closeRowDropdown($row)

    # 2. Feedback visual imediato no botão da linha
    $btn = $row.find('.js-row-action-toggle')
    @setRowLoading($btn, true)

    # 3. Monta payload e URL
    payload = { user_id: userId }
    url     = "#{@apiPath}/pause_indicators/#{action}"

    if action == 'set_offline' or action == 'set_online'
      url           = "#{@apiPath}/pause_indicators/set_state"
      payload.state = if action == 'set_offline' then 'offline' else 'online'
    else if action == 'start_pause'
      pauseTypeId        = $link.data('pause-type-id')
      url                = "#{@apiPath}/pause_indicators/start_pause"
      payload.pause_type_id = pauseTypeId if pauseTypeId?

    # 4. Envia requisição
    # Não chama loadReport() no success: o servidor faz broadcast via WebSocket
    # que já dispara @controllerBind('pause_indicators:changed', => @loadReport()).
    # Isso elimina o loadReport() duplo (WebSocket + success callback) que causava
    # o "trava um pouco" — agora há apenas uma atualização da tabela.
    # Fallback: se o evento WebSocket não chegar em 5s (WebSocket desconectado),
    # força refresh manualmente.
    @ajax(
      id:          "pause_indicators_#{action}_#{userId}"
      type:        'POST'
      url:         url
      data:        JSON.stringify(payload)
      processData: false
      contentType: 'application/json'
      success: =>
        clearTimeout(@_actionFallbackTimer) if @_actionFallbackTimer
        @_actionFallbackTimer = setTimeout(=>
          @_actionFallbackTimer = null
          @setRowLoading($btn, false)
          @loadReport() if window.location.hash is '#report/pause_indicators'
        , 5000)
      error: (xhr) =>
        @setRowLoading($btn, false)
        @loadReport()
        @notify(
          type:    'error'
          msg:     xhr.responseJSON?.error || __('Falha ao alterar status de pausa')
          timeout: 5000
        )
    )

  # Fecha o dropdown Bootstrap 3 da linha (funciona com ou sem portal)
  closeRowDropdown: ($row) ->
    return unless $row?.length
    $dropdown = $row.find('.pause-indicators-actions')
    # Devolve menu do portal ao DOM original antes de fechar
    $portalMenu = $dropdown.data('pause-portal-menu')
    if $portalMenu?.length
      $portalMenu.appendTo($dropdown)
      $portalMenu.removeClass('dropdown-menu--portal-pause')
      $portalMenu.css(position: '', top: '', left: '', zIndex: '')
      $dropdown.removeData('pause-portal-menu')
    $dropdown.removeClass('open')

  setRowLoading: ($btn, loading) ->
    return unless $btn?.length
    if loading
      $btn.prop('disabled', true).addClass('is-loading')
      $btn.find('.status-bar-text').text(App.i18n.translateContent('Aguardando...'))
    else
      $btn.prop('disabled', false).removeClass('is-loading')

  formatDuration: (startedAt) ->
    return '00:00' if !startedAt
    started = new Date(startedAt)
    return '00:00' if isNaN(started.getTime())
    now = new Date()
    sec = Math.max(0, Math.floor((now - started) / 1000))
    h = Math.floor(sec / 3600)
    m = Math.floor((sec % 3600) / 60)
    s = sec % 60
    pad = (n) -> (if n < 10 then "0#{n}" else "#{n}")
    if h > 0 then "#{pad(h)}:#{pad(m)}:#{pad(s)}" else "#{pad(m)}:#{pad(s)}"

  updateAllDurations: ->
    return if window.location.hash isnt '#report/pause_indicators'
    self = @
    @el.find('.js-pause-duration-cell').each ->
      $cell = $(this)
      startedAt = $cell.attr('data-started-at')
      return if !startedAt
      formatted = self.formatDuration(startedAt)
      $cell.find('.js-pause-duration').text(formatted)

  startDurationTimer: ->
    @stopDurationTimer()
    @durationTimer = setInterval(=>
      @updateAllDurations()
    , 1000)

  stopDurationTimer: ->
    if @durationTimer
      clearInterval(@durationTimer)
      @durationTimer = null

  startPolling: ->
    return if @pollTimer
    # Fallback a cada 60s caso o WebSocket falhe ou não esteja disponível; a atualização principal é via evento pause_indicators:changed
    @pollTimer = setInterval(=>
      return if window.location.hash isnt '#report/pause_indicators'
      @loadReport()
    , 60000)

  stopPolling: ->
    return if !@pollTimer
    clearInterval(@pollTimer)
    @pollTimer = null

  release: ->
    $(document).off('click.pause-actions-report')
    clearTimeout(@_actionFallbackTimer) if @_actionFallbackTimer
    @_actionFallbackTimer = null
    @stopPolling()
    @stopDurationTimer()
    super

App.Config.set('report/pause_indicators', App.ReportPauseIndicators, 'Routes')

# Add to Reporting menu
App.Config.set('PauseIndicatorsReport', { 
  prio: 120, 
  name: __('Indicadores de Pausa'), 
  parent: '#report', 
  target: '#report/pause_indicators', 
  permission: ['report', 'report.pause_indicators']
}, 'NavBarRight')
