class App.ReportUserPauses extends App.ControllerAppContent
  @requiredPermission: 'report'

  constructor: ->
    super
    @title __('Relatório de Pausas de Usuários')
    @navupdate '#report/user_pauses'
    @start_date = null
    @end_date = null
    @pause_type_id = 'all'
    @exceeded = 'all'
    @agent_query = ''
    @pauseTypes = []
    @render()

  render: ->
    @html App.view('report/user_pauses')()

    # Set default dates
    endDate = new Date()
    startDate = new Date()
    startDate.setDate(startDate.getDate() - 30)

    @start_date = @formatDate(startDate)
    @end_date = @formatDate(endDate)

    # Initialize date pickers with jQuery datepicker
    @$('.js-start-date').datepicker(
      todayHighlight: true
      autoclose: true
      format: App.i18n.timeFormat()['FORMAT_DATE']
      rtl: App.i18n.dir() is 'rtl'
      container: 'body'
      orientation: 'bottom auto'
      calendarWeeks: App.Config.get('datepicker_show_calendar_weeks')
    ).datepicker('setDate', startDate)
    .on('show', (e) =>
      @positionDatepicker(e.currentTarget)
    )
    .on('changeDate', (e) =>
      @start_date = @formatDate(e.date)
    )

    @$('.js-end-date').datepicker(
      todayHighlight: true
      autoclose: true
      format: App.i18n.timeFormat()['FORMAT_DATE']
      rtl: App.i18n.dir() is 'rtl'
      container: 'body'
      orientation: 'bottom auto'
      calendarWeeks: App.Config.get('datepicker_show_calendar_weeks')
    ).datepicker('setDate', endDate)
    .on('show', (e) =>
      @positionDatepicker(e.currentTarget)
    )
    .on('changeDate', (e) =>
      @end_date = @formatDate(e.date)
    )

    @loadPauseTypes()
    @bindFilters()
    @bindSearch()

  bindFilters: ->
    @$('.js-pause-type').on('change', (e) =>
      @pause_type_id = $(e.currentTarget).val()
    )

    @$('.js-exceeded-filter').on('change', (e) =>
      @exceeded = $(e.currentTarget).val()
    )

    @$('.js-agent-query').on('input', (e) =>
      clearTimeout(@agentQueryTimer) if @agentQueryTimer
      @agentQueryTimer = setTimeout((=>
        @agent_query = $(e.currentTarget).val()
      ), 400)
    )

  bindSearch: ->
    @$('.js-report-search').on('click', (e) =>
      e.preventDefault()
      @loadReport()
    )

  loadPauseTypes: ->
    @ajax(
      id:          'user_pauses_report_pause_types'
      type:        'GET'
      url:         "#{@apiPath}/pause_types"
      processData: true
      success:     (data) =>
        if Array.isArray(data)
          @pauseTypes = data.filter((p) -> p.active)
        else
          @pauseTypes = []
        @renderPauseTypeOptions()
      error: =>
        @pauseTypes = []
        @renderPauseTypeOptions()
    )

  renderPauseTypeOptions: ->
    options = []
    options.push "<option value=\"all\">#{__('Todos')}</option>"
    options.push "<option value=\"login_logout\">#{__('Login/Logout')}</option>"
    for pauseType in @pauseTypes
      options.push "<option value=\"#{pauseType.id}\">#{App.Utils.htmlEscape(pauseType.name)}</option>"
    @$('.js-pause-type').html(options.join(''))
    @$('.js-pause-type').val(@pause_type_id)

  formatDate: (date) ->
    return '' unless date
    year = date.getFullYear()
    month = String(date.getMonth() + 1).padStart(2, '0')
    day = String(date.getDate()).padStart(2, '0')
    "#{year}-#{month}-#{day}"

  positionDatepicker: (input) ->
    # Use setTimeout to ensure the picker is fully rendered before repositioning
    setTimeout(=>
      picker = $('.datepicker.datepicker-dropdown:visible')
      return unless picker.length

      $input = $(input)
      offset = $input.offset()
      height = $input.outerHeight() || 0
      width = $input.outerWidth() || 0
      
      # Position the picker below the input field, aligned to its left edge
      picker.css(
        position: 'absolute'
        top: offset.top + height + 2
        left: offset.left
        right: 'auto'
      )
    , 10)

  formatDateFromValue: (value) ->
    return '' unless value
    timeObject = new Date(value)
    return '' if isNaN(timeObject.getTime())
    d = App.Utils.formatTime(timeObject.getDate(), 2)
    m = App.Utils.formatTime(timeObject.getMonth() + 1, 2)
    y = timeObject.getFullYear()
    "#{y}-#{m}-#{d}"

  formatTimeFromValue: (value) ->
    return '' unless value
    timeObject = new Date(value)
    return '' if isNaN(timeObject.getTime())
    H = App.Utils.formatTime(timeObject.getHours(), 2)
    M = App.Utils.formatTime(timeObject.getMinutes(), 2)
    "#{H}:#{M}"

  loadReport: ->
    return if !@start_date || !@end_date

    @startLoading()
    @ajax(
      id:          'user_pauses_report'
      type:        'GET'
      url:         "#{@apiPath}/reports/user_pauses"
      data:
        start_date: @start_date
        end_date: @end_date
        pause_type_id: @pause_type_id
        exceeded: @exceeded
        agent_query: @agent_query
      processData: true
      success:     (data, status, xhr) =>
        @stopLoading()
        @renderReport(data)
      error: (xhr) =>
        @stopLoading()
        @notify(
          type:    'error'
          msg:     __('Failed to load report')
          timeout: 5000
        )
    )

  renderReport: (data) ->
    @el.find('.js-report-content').html App.view('report/user_pauses_content')(
      data: data
      formatDuration: @formatDuration
      formatDate: @formatDateFromValue
      formatTime: @formatTimeFromValue
    )

  formatDuration: (totalSeconds) ->
    totalSeconds = parseInt(totalSeconds) || 0
    hours = Math.floor(totalSeconds / 3600)
    minutes = Math.floor((totalSeconds % 3600) / 60)
    seconds = totalSeconds % 60
    
    pad = (num) ->
      if num < 10 then '0' + num else String(num)

    "#{pad(hours)}:#{pad(minutes)}:#{pad(seconds)}"

App.Config.set('report/user_pauses', App.ReportUserPauses, 'Routes')

# Add to Reporting menu
App.Config.set('UserPausesReport', { 
  prio: 100, 
  name: __('Pausas de Usuários'), 
  parent: '#report', 
  target: '#report/user_pauses', 
  permission: ['report']
}, 'NavBarRight')
