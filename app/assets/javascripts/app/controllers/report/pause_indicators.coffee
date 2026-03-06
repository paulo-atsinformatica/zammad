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
    @selectedUserIds = []
    @restoreSelectedFromStorage()
    @render()

  restoreSelectedFromStorage: ->
    try
      stored = sessionStorage.getItem('report/pause_indicators/colaboradores')
      if stored
        parsed = JSON.parse(stored)
        @selectedUserIds = parsed if Array.isArray(parsed)
    catch e
      @selectedUserIds = []

  saveSelectedToStorage: ->
    try
      sessionStorage.setItem('report/pause_indicators/colaboradores', JSON.stringify(@selectedUserIds))
    catch e
      #

  render: ->
    @html App.view('report/pause_indicators')()
    @loadReport()
    @bindFilterEvents()
    @startPolling()
    @startDurationTimer()

  bindFilterEvents: ->
    @el.find('.js-apply-colaboradores-filter').on('click', => @applyColaboradoresFilter())
    @el.find('.js-clear-colaboradores-filter').on('click', => @clearColaboradoresFilter())

  applyColaboradoresFilter: ->
    @selectedUserIds = @el.find('.js-colaborador-checkbox:checked').map(-> parseInt($(this).val(), 10) ).get()
    @saveSelectedToStorage()
    @loadReport()

  clearColaboradoresFilter: ->
    @selectedUserIds = []
    @el.find('.js-colaborador-checkbox').prop('checked', false)
    @saveSelectedToStorage()
    @loadReport()

  renderColaboradoresFilter: (agents) ->
    return if !agents || agents.length is 0
    @agents = agents
    html = '<div class="pause-indicators-colaboradores-list">'
    for agent in agents
      checked = @selectedUserIds.indexOf(agent.id) >= 0
      safeName = App.Utils.htmlEscape(agent.name)
      html += "<label class=\"pause-indicators-colaborador-item\"><input type=\"checkbox\" class=\"js-colaborador-checkbox\" value=\"#{agent.id}\" #{if checked then 'checked' else ''}> #{safeName}</label>"
    html += '</div>'
    @el.find('.js-colaboradores-filter').html(html)

  loadReport: ->
    return if window.location.hash isnt '#report/pause_indicators'
    return if @loadInProgress
    @loadInProgress = true
    params = {}
    if @selectedUserIds.length > 0
      params.user_ids = @selectedUserIds
    @ajax(
      id:          'pause_indicators_report'
      type:        'GET'
      url:         "#{@apiPath}/reports/pause_indicators"
      data:        params
      processData: true
      success:     (data) =>
        @loadInProgress = false
        return if window.location.hash isnt '#report/pause_indicators'
        @renderColaboradoresFilter(data.agents) if data.agents
        @renderReport(data)
        @startDurationTimer()
      error: (xhr, statusText, error) =>
        @loadInProgress = false
        return if statusText is 'abort' || (xhr && xhr.statusText is 'abort')
        @notify(
          type:    'error'
          msg:     __('Failed to load report')
          timeout: 5000
        )
    )

  renderReport: (data) ->
    @el.find('.js-report-content').html App.view('report/pause_indicators_content')(
      data: data
    )
    @updateAllDurations()

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
    @pollTimer = setInterval(=>
      return if window.location.hash isnt '#report/pause_indicators'
      @loadReport()
    , 10000)

  stopPolling: ->
    return if !@pollTimer
    clearInterval(@pollTimer)
    @pollTimer = null

  release: ->
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
