# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: relatório personalizado.

class App.ReportCustom extends App.ControllerAppContent
  @requiredPermission: ['report.custom']

  elements:
    '.js-reports': 'reportsList'
    '.js-runs': 'runsList'

  events:
    'click .js-new':           'new'
    'click .js-edit':          'edit'
    'click .js-delete':        'delete'
    'click .js-generate':      'generate'
    'click .js-visibility':    'changeVisibility'

  constructor: ->
    super
    @title __('Custom Report'), true
    @navupdate '#report/custom'

    @visibility = 'all'
    @reports = []
    @runs = []

    # Progresso e conclusão chegam pelo WebSocket. O polling abaixo é só
    # salvaguarda para quando o WebSocket não estiver disponível.
    @controllerBind('CustomReportRun:progress', @onRunProgress)
    @controllerBind('CustomReportRun:finished', @onRunFinished)

    @render()
    @loadReports()
    @loadRuns()

  render: ->
    @html App.view('report/custom')(
      visibility: @visibility
    )

  loadReports: =>
    @ajax(
      id:          'custom_reports_index'
      type:        'GET'
      url:         "#{@apiPath}/custom_reports"
      data:        { visibility: @visibility }
      processData: true
      success: (data) =>
        @reports   = data.custom_reports or []
        @canShare  = data.can_share or ['personal']
        @renderReports()
    )

  renderReports: =>
    return if !@reportsList
    @reportsList.html App.view('report/custom_reports')(
      reports: @reports
    )

  loadRuns: =>
    @ajax(
      id:          'custom_report_runs_index'
      type:        'GET'
      url:         "#{@apiPath}/custom_report_runs"
      processData: true
      success: (data) =>
        @runs = data.custom_report_runs or []
        @renderRuns()
        @scheduleRunPolling()
    )

  renderRuns: =>
    return if !@runsList
    @runsList.html App.view('report/custom_runs')(
      runs:    @runs
      apiPath: @apiPath
    )

  # Só faz polling enquanto houver geração em andamento, e só como reserva
  # caso o evento de WebSocket não chegue.
  scheduleRunPolling: =>
    pending = _.filter(@runs, (run) -> run.status in ['pending', 'running'])
    return if _.isEmpty(pending)

    @delay(@loadRuns, 5000, 'custom-report-runs-poll')

  changeVisibility: (e) =>
    e.preventDefault()
    @visibility = $(e.currentTarget).data('visibility')
    @$('.js-visibility').removeClass('is-selected')
    $(e.currentTarget).addClass('is-selected')
    @loadReports()

  new: (e) =>
    e.preventDefault()
    new App.ControllerGenericNew(
      pageData:
        title:   __('Custom Report')
        object:  __('Custom Report')
        objects: __('Custom Reports')
      genericObject: 'CustomReport'
      container:     @el.closest('.content')
      large:         true
      callback:      @loadReports
    )

  edit: (e) =>
    e.preventDefault()
    new App.ControllerGenericEdit(
      id: $(e.currentTarget).closest('[data-id]').data('id')
      pageData:
        title:   __('Custom Report')
        object:  __('Custom Report')
        objects: __('Custom Reports')
      genericObject: 'CustomReport'
      container:     @el.closest('.content')
      large:         true
      callback:      @loadReports
    )

  delete: (e) =>
    e.preventDefault()
    id = $(e.currentTarget).closest('[data-id]').data('id')

    new App.ControllerConfirm(
      message:      __('Are you sure?')
      container:    @el.closest('.content')
      callback:     =>
        @ajax(
          id:          "custom_report_destroy_#{id}"
          type:        'DELETE'
          url:         "#{@apiPath}/custom_reports/#{id}"
          processData: true
          success:     @loadReports
        )
    )

  generate: (e) =>
    e.preventDefault()
    target = $(e.currentTarget)
    id     = target.closest('[data-id]').data('id')
    format = target.data('format') or 'csv'

    @ajax(
      id:          "custom_report_generate_#{id}"
      type:        'POST'
      url:         "#{@apiPath}/custom_reports/#{id}/generate"
      data:        JSON.stringify(format: format)
      contentType: 'application/json'
      processData: false
      success: =>
        @notify(
          type:    'success'
          msg:     App.i18n.translateContent('Report queued. You will be notified when it is ready to download.')
          timeout: 4000
        )
        @loadRuns()
      error: (xhr) =>
        @notify(
          type:    'error'
          msg:     xhr.responseJSON?.error || App.i18n.translateContent('Could not queue the report.')
          timeout: 5000
        )
    )

  onRunProgress: (data) =>
    return if !data
    run = _.find(@runs, (item) -> item.id is data.id)

    # Uma geração recém-enfileirada por outra aba ainda não está na lista.
    return @loadRuns() if !run

    run.status         = data.status
    run.processed_rows = data.processed_rows
    run.total_rows     = data.total_rows
    @renderRuns()

  onRunFinished: (data) =>
    return if !data
    # Recarrega para obter tamanho do arquivo e o link de download.
    @loadRuns()

App.Config.set('report/custom', App.ReportCustom, 'Routes')

# Item no menu de Relatórios. target: '_blank' abre numa guia nova, de forma
# que o usuário continue usando o Zammad na guia original enquanto o relatório
# é montado e gerado.
App.Config.set('CustomReport', {
  prio: 100,
  name: __('Custom Report'),
  parent: '#report',
  target: '#report/custom',
  targetAttribute: '_blank',
  permission: ['report.custom']
}, 'NavBarRight')
