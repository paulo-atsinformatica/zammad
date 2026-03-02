# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class App.ReportTicketTimeTrackings extends App.ControllerAppContent
  @requiredPermission: ['report', 'report.ticket_time_trackings']

  constructor: ->
    super
    @title __('Relatório de Tempo de Atendimento')
    @navupdate '#report/ticket_time_trackings'
    @open_start_date = null
    @open_end_date = null
    @close_start_date = null
    @close_end_date = null
    @ticket_query = ''
    @agent_id = ''
    @selectedTeams = App.SessionStorage.get('report/ticket_time_trackings/equipe') || []
    @teams = []
    @agents = []
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
    @loadReport()

  bindFilters: ->
    @$('.js-ticket-query').on('input', (e) =>
      clearTimeout(@ticketQueryTimer) if @ticketQueryTimer
      @ticketQueryTimer = setTimeout((=>
        @ticket_query = $(e.currentTarget).val()
      ), 400)
    )

    @$('.js-agent-select').on('change', (e) =>
      @agent_id = $(e.currentTarget).val()
    )

  renderAgentOptions: ->
    $select = @$('.js-agent-select')
    return if !$select.length
    currentVal = @agent_id
    options = ["<option value=\"\">#{__('Todos')}</option>"]
    for agent in @agents
      options.push "<option value=\"#{agent.id}\">#{App.Utils.htmlEscape(agent.name)}</option>"
    $select.html(options.join(''))
    $select.val(currentVal) if currentVal

  renderEquipeFilter: ->
    $container = @el.find('.js-equipe-filter')
    return if !$container.length
    if @teams.length == 0
      $container.empty()
      return
    list = @teams.map (team) =>
      checked = if @selectedTeams.indexOf(team) >= 0 then ' checked' else ''
      "<label class=\"inline-label checkbox-replacement\"><input type=\"checkbox\" class=\"js-team-checkbox\" value=\"#{App.Utils.htmlEscape(team)}\"#{checked}><span class=\"label-text\">#{App.Utils.htmlEscape(team)}</span></label>"
    $container.html("<div class=\"checkbox-list\">#{list.join('')}</div>")
    $container.find('.js-team-checkbox').off('change').on('change', (=> @onTeamCheckboxChange()))

  onTeamCheckboxChange: ->
    @applyEquipeFilter()

  applyEquipeFilter: ->
    @selectedTeams = @el.find('.js-team-checkbox:checked').map(-> $(this).val()).get()
    App.SessionStorage.set('report/ticket_time_trackings/equipe', @selectedTeams)
    @loadReport()

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
    data =
      open_start_date: @open_start_date
      open_end_date: @open_end_date
      close_start_date: @close_start_date
      close_end_date: @close_end_date
      ticket_query: @ticket_query
      agent_id: @agent_id
    if @selectedTeams.length > 0
      data.equipe = @selectedTeams

    @ajax(
      id:          'ticket_time_trackings_report'
      type:        'GET'
      url:         "#{@apiPath}/reports/ticket_time_trackings"
      data:        data
      processData: true
      success:     (data, status, xhr) =>
        @stopLoading()
        @teams = data.teams || []
        @agents = data.agents || []
        @renderAgentOptions()
        @renderEquipeFilter()
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
  permission: ['report', 'report.ticket_time_trackings']
}, 'NavBarRight')
