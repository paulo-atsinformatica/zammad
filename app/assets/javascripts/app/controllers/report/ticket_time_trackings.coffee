# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class App.ReportTicketTimeTrackings extends App.ControllerAppContent
  @requiredPermission: 'report'

  constructor: ->
    super
    @title __('Relatório de Tempo de Atendimento')
    @navupdate '#report/ticket_time_trackings'
    @open_start_date = null
    @open_end_date = null
    @close_start_date = null
    @close_end_date = null
    @ticket_query = ''
    @agent_query = ''
    @render()

  render: ->
    @html App.view('report/ticket_time_trackings')()

    # Set default dates
    endDate = new Date()
    startDate = new Date()
    startDate.setDate(startDate.getDate() - 30)

    @open_start_date = @formatDate(startDate)
    @open_end_date = @formatDate(endDate)
    @close_start_date = ''
    @close_end_date = ''

    # Initialize date pickers with jQuery datepicker
    @$('.js-open-start-date').datepicker(
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
      @open_start_date = @formatDate(e.date)
    )

    @$('.js-open-end-date').datepicker(
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
      @open_end_date = @formatDate(e.date)
    )

    @$('.js-close-start-date').datepicker(
      todayHighlight: true
      autoclose: true
      format: App.i18n.timeFormat()['FORMAT_DATE']
      rtl: App.i18n.dir() is 'rtl'
      container: 'body'
      orientation: 'bottom auto'
      calendarWeeks: App.Config.get('datepicker_show_calendar_weeks')
    ).on('show', (e) =>
      @positionDatepicker(e.currentTarget)
    )
    .on('changeDate', (e) =>
      @close_start_date = @formatDate(e.date)
    )

    @$('.js-close-end-date').datepicker(
      todayHighlight: true
      autoclose: true
      format: App.i18n.timeFormat()['FORMAT_DATE']
      rtl: App.i18n.dir() is 'rtl'
      container: 'body'
      orientation: 'bottom auto'
      calendarWeeks: App.Config.get('datepicker_show_calendar_weeks')
    ).on('show', (e) =>
      @positionDatepicker(e.currentTarget)
    )
    .on('changeDate', (e) =>
      @close_end_date = @formatDate(e.date)
    )

    @bindFilters()
    @bindSearch()

  bindFilters: ->
    @$('.js-ticket-query').on('input', (e) =>
      clearTimeout(@ticketQueryTimer) if @ticketQueryTimer
      @ticketQueryTimer = setTimeout((=>
        @ticket_query = $(e.currentTarget).val()
      ), 400)
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

  formatDateTimeFromValue: (value) ->
    return '' unless value
    timeObject = new Date(value)
    return '' if isNaN(timeObject.getTime())
    d = App.Utils.formatTime(timeObject.getDate(), 2)
    m = App.Utils.formatTime(timeObject.getMonth() + 1, 2)
    y = timeObject.getFullYear()
    H = App.Utils.formatTime(timeObject.getHours(), 2)
    M = App.Utils.formatTime(timeObject.getMinutes(), 2)
    "#{y}-#{m}-#{d} #{H}:#{M}"

  loadReport: ->
    return if !@open_start_date || !@open_end_date

    @startLoading()
    @ajax(
      id:          'ticket_time_trackings_report'
      type:        'GET'
      url:         "#{@apiPath}/reports/ticket_time_trackings"
      data:
        open_start_date: @open_start_date
        open_end_date: @open_end_date
        close_start_date: @close_start_date
        close_end_date: @close_end_date
        ticket_query: @ticket_query
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
    @el.find('.js-report-content').html App.view('report/ticket_time_trackings_content')(
      data: data
      formatDuration: @formatDuration
      formatDate: @formatDateFromValue
      formatDateTime: @formatDateTimeFromValue
    )

  formatDuration: (totalSeconds) ->
    totalSeconds = parseInt(totalSeconds) || 0
    hours = Math.floor(totalSeconds / 3600)
    minutes = Math.floor((totalSeconds % 3600) / 60)
    seconds = totalSeconds % 60
    
    pad = (num) ->
      if num < 10 then '0' + num else String(num)

    "#{pad(hours)}:#{pad(minutes)}:#{pad(seconds)}"

App.Config.set('report/ticket_time_trackings', App.ReportTicketTimeTrackings, 'Routes')

# Add to Reporting menu
App.Config.set('TicketTimeTrackingsReport', { 
  prio: 110, 
  name: __('Tempo de Atendimento'), 
  parent: '#report', 
  target: '#report/ticket_time_trackings', 
  permission: ['report']
}, 'NavBarRight')
