# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class App.ReportPauseIndicators extends App.ControllerAppContent
  @requiredPermission: ['report', 'report.pause_indicators']

  constructor: ->
    super
    @title __('Indicadores de Pausa')
    @navupdate '#report/pause_indicators'
    @pollTimer = null
    @durationTimer = null
    @selectedTeams = App.SessionStorage.get('report/pause_indicators/equipe') || []
    @teams = []
    @render()

  render: ->
    @html App.view('report/pause_indicators')()
    @renderTeamsFilter()
    @loadReport()
    @startPolling()
    @startDurationTimer()

  renderTeamsFilter: ->
    $container = @el.find('.js-report-filters')
    if @teams.length == 0
      $container.empty()
      return
    list = @teams.map (team) =>
      checked = if @selectedTeams.indexOf(team) >= 0 then ' checked' else ''
      "<label class=\"inline-label checkbox-replacement\"><input type=\"checkbox\" class=\"js-team-checkbox\" value=\"#{App.Utils.htmlEscape(team)}\"#{checked}><span class=\"label-text\">#{App.Utils.htmlEscape(team)}</span></label>"
    html = """
      <div class="report-filters well report-filters-equipe">
        <div class="report-filters-grid">
          <div class="form-group report-filter-field report-filter-field--equipe">
            <label>#{App.i18n.translateContent('Equipe')}</label>
            <div class="js-teams-list checkbox-list">#{list.join('')}</div>
          </div>
        </div>
        <div class="report-filters-actions">
          <button type="button" class="btn btn--primary js-apply-equipe-filter">#{App.i18n.translateContent('Aplicar filtro')}</button>
        </div>
      </div>
    """
    $container.html(html)
    $container.find('.js-team-checkbox').on('change', (=> @onTeamCheckboxChange()))
    $container.find('.js-apply-equipe-filter').on('click', (=> @applyEquipeFilter()))

  onTeamCheckboxChange: ->
    @applyEquipeFilter()

  applyEquipeFilter: ->
    @selectedTeams = @el.find('.js-team-checkbox:checked').map(-> $(this).val()).get()
    App.SessionStorage.set('report/pause_indicators/equipe', @selectedTeams)
    @loadReport()

  loadReport: ->
    return if window.location.hash isnt '#report/pause_indicators'
    url = "#{@apiPath}/reports/pause_indicators"
    if @selectedTeams.length > 0
      url += '?' + $.param(equipe: @selectedTeams)
    @ajax(
      id:          'pause_indicators_report'
      type:        'GET'
      url:         url
      processData: true
      success:     (data) =>
        return if window.location.hash isnt '#report/pause_indicators'
        @teams = data.teams || []
        @renderTeamsFilter()
        @renderReport(data)
        @startDurationTimer()
      error: (xhr) =>
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
