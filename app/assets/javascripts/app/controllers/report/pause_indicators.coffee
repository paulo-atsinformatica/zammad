# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class App.ReportPauseIndicators extends App.ControllerAppContent
  @requiredPermission: 'report'

  constructor: ->
    super
    @title __('Indicadores de Pausa')
    @navupdate '#report/pause_indicators'
    @pollTimer = null
    @render()

  render: ->
    @html App.view('report/pause_indicators')()
    @loadReport()
    @startPolling()

  loadReport: ->
    @ajax(
      id:          'pause_indicators_report'
      type:        'GET'
      url:         "#{@apiPath}/reports/pause_indicators"
      processData: true
      success:     (data) =>
        @renderReport(data)
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

  startPolling: ->
    return if @pollTimer
    @pollTimer = setInterval((=> @loadReport()), 10000)

  stopPolling: ->
    return if !@pollTimer
    clearInterval(@pollTimer)
    @pollTimer = null

  release: ->
    @stopPolling()
    super

App.Config.set('report/pause_indicators', App.ReportPauseIndicators, 'Routes')

# Add to Reporting menu
App.Config.set('PauseIndicatorsReport', { 
  prio: 120, 
  name: __('Indicadores de Pausa'), 
  parent: '#report', 
  target: '#report/pause_indicators', 
  permission: ['report']
}, 'NavBarRight')
