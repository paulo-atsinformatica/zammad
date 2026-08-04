# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class App.TicketZoomTimeTracking extends App.Controller
  elements:
    '.js-tt-start': 'startButton'
    '.js-tt-pause': 'pauseButton'
    '.js-tt-timer': 'timerDisplay'

  events:
    'click .js-tt-start':  'onStartClick'
    'click .js-tt-pause':  'onPauseClick'
    'click .js-tt-others': 'onOthersClick'

  # Base do cronômetro: o acumulado deste usuário NO TICKET, e não só do registro
  # atual.
  #
  # Cada passagem pelo ticket cria um registro próprio — é isso que permite ver o
  # tempo por atendente. Sem somar as anteriores, o agente que devolve e recebe o
  # ticket de volta via 00:00:00 apesar de já ter trabalhado nele.
  #
  # ticket_total_seconds é calculado pelo servidor (ver
  # TicketTimeTracking#ticket_total_seconds) e não inclui o segmento em curso,
  # que o cronômetro soma sozinho.
  baseSeconds: (data, fallback = 0) ->
    return fallback if !data
    return data.ticket_total_seconds if data.ticket_total_seconds?
    return data.total_seconds if data.total_seconds?
    fallback

  constructor: (params) ->
    super
    @ticket = params.ticket
    @ticket_id = @ticket.id
    @currentUser = App.User.current()
    @tracking = null
    @timer = null
    @totalSeconds = 0
    @isPaused = false

    # Listen for user state changes (pause/offline)
    @controllerBind('user_state:changed', @onUserStateChanged)
    @controllerBind('pause:started', @onPauseStarted)
    @controllerBind('pause:ended', @onPauseEnded)
    @controllerBind('pause_control:logout', @onPauseControlLogout)
    @controllerBind('pause_control:login', @onPauseControlLogin)

    # Listen for ticket updates
    @controllerBind('ticket:update', @onTicketUpdate)
    @controllerBind('ui::ticket::all::loaded', @onTicketLoaded)
    @controllerBind('ui::ticket::load', @onTicketLoaded)
    @ticket.on('change:state_id', @onTicketStateChange)

    # Listen for WebSocket time tracking events (real-time sync)
    @controllerBind('TicketTimeTracking:stateChange', @onTimeTrackingStateChange)
    @controllerBind('TicketTimeTracking:destroyed', @onTimeTrackingDestroyed)
    @controllerBind('Ticket:timeTrackingChange', @onTicketTimeTrackingChange)
    @controllerBind('TicketTimeTracking:create', @onTimeTrackingCreated)
    @controllerBind('TicketTimeTracking:update', @onTimeTrackingUpdated)

    @render()
    @checkCurrentTracking()
    @loadSummary()

  render: ->
    @html App.view('ticket_zoom/time_tracking')()
    @updateButtonStates()

  # Tempo por atendente. Um ticket costuma passar de mão, e sem isto cada pessoa
  # só enxergava o próprio tempo. Só aparece quando mais de um atendente
  # trabalhou no ticket — para um só, o cronômetro já diz tudo.
  loadSummary: =>
    @ajax(
      id:          "tt_summary_#{@ticket_id}"
      type:        'GET'
      url:         "#{@apiPath}/tickets/#{@ticket_id}/time_tracking/summary"
      processData: true
      success:     (data) =>
        @renderSummary(data)
      error: =>
        # Não é informação essencial: se falhar, o player segue funcionando.
        @$('.js-tt-others-wrap').addClass('hide')
    )

  renderSummary: (data) ->
    entries = data?.entries or []

    # Guarda o acumulado DESTE usuário no ticket. É o que o cronômetro mostra
    # quando não há registro em aberto — ver checkCurrentTracking. As duas
    # chamadas são assíncronas, então quem chegar por último aplica o valor.
    mine = _.find(entries, (entry) => entry.user_id is @currentUser?.id)
    @summarySeconds = mine?.total_seconds or 0
    if !@tracking && @summarySeconds
      @totalSeconds = @summarySeconds
      @renderTime()

    wrap = @$('.js-tt-others-wrap')
    return if !wrap.length

    if entries.length < 2
      @closeOthers()
      wrap.addClass('hide')
      return

    @renderOthersPopover(entries, data.total_seconds or 0)
    wrap.removeClass('hide')

  # Conteúdo do popup: o ticket em questão e o tempo de cada atendente. Montado
  # com jQuery, e não por interpolação de string, para o nome do usuário (dado
  # digitado por gente) não virar HTML.
  renderOthersPopover: (entries, totalSeconds) ->
    popover = @$('.js-tt-others-popover')
    return if !popover.length

    popover.empty()

    $('<div/>')
      .addClass('tt-others-title')
      .text("#{App.Config.get('ticket_hook')}#{@ticket.number}")
      .appendTo(popover)

    list = $('<ul/>').addClass('tt-others-list').appendTo(popover)

    for entry in entries
      row = $('<li/>').appendTo(list)
      row.toggleClass('is-running', !!entry.running)
      $('<span/>').addClass('tt-others-name').text(entry.user or '-').appendTo(row)
      $('<span/>').addClass('tt-others-value').text(entry.formatted).appendTo(row)

    total = $('<div/>').addClass('tt-others-total').appendTo(popover)
    $('<span/>').text(App.i18n.translateInline('Total')).appendTo(total)
    $('<span/>').addClass('tt-others-value').text(@formatSeconds(totalSeconds)).appendTo(total)

  onOthersClick: (e) ->
    e.preventDefault()
    e.stopPropagation()

    if @$('.js-tt-others-popover').hasClass('hide') then @openOthers() else @closeOthers()

  openOthers: ->
    @$('.js-tt-others-popover').removeClass('hide')
    @$('.js-tt-others').attr('aria-expanded', 'true')

    # Fecha ao clicar fora. Namespaced para o unbind não derrubar outros
    # handlers do documento, e removido em closeOthers e no release.
    $(document).on("click.tt-others-#{@ticket_id}", (event) =>
      return if $(event.target).closest('.js-tt-others-wrap').length
      @closeOthers()
    )

  closeOthers: ->
    @$('.js-tt-others-popover').addClass('hide')
    @$('.js-tt-others').attr('aria-expanded', 'false')
    $(document).off("click.tt-others-#{@ticket_id}")

  formatSeconds: (seconds) ->
    pad = (value) -> if value < 10 then "0#{value}" else "#{value}"
    "#{pad(Math.floor(seconds / 3600))}:#{pad(Math.floor((seconds % 3600) / 60))}:#{pad(seconds % 60)}"

  checkCurrentTracking: ->
    @ajax(
      id:          "tt_current_#{@ticket_id}"
      type:        'GET'
      url:         "#{@apiPath}/tickets/#{@ticket_id}/time_tracking/current"
      processData: true
      success:     (data) =>
        if data && (data.is_active || data.id)
          @tracking = data
          @totalSeconds = @baseSeconds(data)
          
          # Check if tracking is paused (either active+paused or deactivated)
          if data.is_active
            @isPaused = !!data.paused_at
            @isDeactivated = false
          else
            # Deactivated tracking (from closed ticket) - can be resumed
            @isPaused = true
            @isDeactivated = true
          
          if !@isPaused && data.is_active
            @startTimer(data.resumed_at || data.started_at)
          else
            @stopTimer()
          
          @updateButtonStates()
          @renderTime()
        else
          @tracking = null
          # O acumulado das passagens anteriores continua valendo mesmo sem
          # registro em aberto: quem devolveu o ticket e o recebeu de volta
          # precisa ver quanto já trabalhou nele ANTES de clicar em iniciar.
          # O total vem do resumo, que já é carregado no construtor.
          @totalSeconds = @summarySeconds or 0
          @isPaused = false
          @isDeactivated = false
          @stopTimer()
          @updateButtonStates()
          @renderTime()
      error: =>
        @tracking = null
        @totalSeconds = 0
        @isPaused = false
        @isDeactivated = false
        @stopTimer()
        @updateButtonStates()
    )

  # Check if user can interact with time tracking
  canInteract: ->
    pauseLoggedIn = App.Config.get('pause_control_logged_in')
    return false if pauseLoggedIn is false
    return false if !@currentUser?.permission('ticket.time_tracking')
    return false if @ticket.owner_id != @currentUser.id # Must be assigned to user
    return false if @currentUser.in_pause # User is in global pause
    return false if @currentUser.current_state == 'offline' # User is offline
    true

  # Check if can start tracking
  canStart: ->
    return false if !@canInteract()
    return false if @tracking # Has existing tracking (use resume instead)
    return false if @isTicketClosed() # Ticket is closed
    true

  # Check if can pause tracking
  canPause: ->
    return false if !@canInteract()
    return false if !@tracking?.is_active # Not tracking
    return false if @isPaused # Already paused
    true

  # Check if can resume tracking
  canResume: ->
    return false if !@canInteract()
    return false if !@tracking # No tracking to resume
    return false if !@isPaused # Not paused
    return false if @isTicketClosed() # Closed tickets cannot be resumed
    # Can resume if tracking is paused (active or deactivated)
    true

  isTicketClosed: ->
    @ticket.state?.state_type?.name == 'closed' || @ticket.state?.name == 'closed'

  updateButtonStates: ->
    # Start button - shows play icon, enabled when can start or resume
    if @canStart()
      @startButton.prop('disabled', false).removeClass('is-disabled').addClass('is-ready')
      @startButton.attr('title', App.i18n.translateContent('Iniciar contagem'))
    else if @canResume()
      @startButton.prop('disabled', false).removeClass('is-disabled').addClass('is-ready')
      @startButton.attr('title', App.i18n.translateContent('Retomar contagem'))
    else
      @startButton.prop('disabled', true).addClass('is-disabled').removeClass('is-ready')
      @startButton.attr('title', @getDisabledReason())

    # Pause button - shows pause icon, enabled when can pause
    if @canPause()
      @pauseButton.prop('disabled', false).removeClass('is-disabled').addClass('is-ready')
      @pauseButton.attr('title', App.i18n.translateContent('Pausar contagem'))
    else
      @pauseButton.prop('disabled', true).addClass('is-disabled').removeClass('is-ready')
      @pauseButton.attr('title', App.i18n.translateContent('Pausar contagem'))

    # Timer display - show current state
    if @tracking
      @timerDisplay.addClass('is-active')
      if @isPaused || @isDeactivated
        @timerDisplay.addClass('is-paused')
      else
        @timerDisplay.removeClass('is-paused')
      @renderTime()
    else
      @timerDisplay.removeClass('is-active is-paused')

  getDisabledReason: ->
    pauseLoggedIn = App.Config.get('pause_control_logged_in')
    if pauseLoggedIn is false
      return App.i18n.translateContent('Faça login no controle de pausas')
    if !@currentUser?.permission('ticket.time_tracking')
      return App.i18n.translateContent('Sem permissão para controle de tempo')
    if @ticket.owner_id != @currentUser.id
      return App.i18n.translateContent('Ticket não está atribuído a você')
    if @currentUser.in_pause
      return App.i18n.translateContent('Você está em pausa')
    if @currentUser.current_state == 'offline'
      return App.i18n.translateContent('Você está offline')
    if @isTicketClosed()
      return App.i18n.translateContent('Ticket está fechado')
    if @tracking?.is_active && !@isPaused
      return App.i18n.translateContent('Contagem já iniciada')
    if @tracking && @isPaused
      return App.i18n.translateContent('Retomar contagem')
    App.i18n.translateContent('Iniciar contagem')

  onStartClick: (e) ->
    e.preventDefault()
    
    if @canResume()
      @resumeTracking()
    else if @canStart()
      @startTracking()

  onPauseClick: (e) ->
    e.preventDefault()
    
    if @canPause()
      @pauseTracking()

  startTracking: ->
    @startButton.prop('disabled', true)
    
    @ajax(
      id:          "tt_start_#{@ticket_id}"
      type:        'POST'
      url:         "#{@apiPath}/tickets/#{@ticket_id}/time_tracking/start"
      dataType:    'json'
      processData: true
      # A 409 (outro ticket já em atendimento) é tratada aqui com o diálogo de
      # troca. Sem isso o handler global de ajax mostra um modal de erro técnico
      # por cima, já que ele só ignora 401/403/404/422/502.
      failResponseNoTrigger: true
      success:     (data) =>
        @tracking = data
        @totalSeconds = @baseSeconds(data)
        @isPaused = false
        @startTimer(data.resumed_at || data.started_at)
        @updateButtonStates()
        @notify(
          type:    'success'
          msg:     App.i18n.translateContent('Contagem iniciada')
          timeout: 2000
        )
      error: (xhr) =>
        @updateButtonStates()
        # Parse JSON response if not already parsed
        responseData = xhr.responseJSON
        if !responseData && xhr.responseText
          try
            responseData = JSON.parse(xhr.responseText)
          catch e
            responseData = {}
        
        # Check for existing ticket - show dialog only, no error toast
        if responseData?.existing_ticket_id
          @showSwitchDialog(responseData)
          return
        
        @notify(
          type:    'error'
          msg:     responseData?.error || App.i18n.translateContent('Erro ao iniciar contagem')
          timeout: 3000
        )
    )

  pauseTracking: ->
    @pauseButton.prop('disabled', true)
    
    @ajax(
      id:          "tt_pause_#{@ticket_id}"
      type:        'POST'
      url:         "#{@apiPath}/tickets/#{@ticket_id}/time_tracking/pause"
      processData: true
      success:     (data) =>
        @tracking = data
        @totalSeconds = @baseSeconds(data, @totalSeconds)
        @isPaused = true
        @stopTimer()
        @updateButtonStates()
        @renderTime()
        @notify(
          type:    'success'
          msg:     App.i18n.translateContent('Contagem pausada')
          timeout: 2000
        )
      error: (xhr) =>
        @updateButtonStates()
        @notify(
          type:    'error'
          msg:     xhr.responseJSON?.error || App.i18n.translateContent('Erro ao pausar contagem')
          timeout: 3000
        )
    )

  resumeTracking: ->
    @startButton.prop('disabled', true)
    
    @ajax(
      id:          "tt_resume_#{@ticket_id}"
      type:        'POST'
      url:         "#{@apiPath}/tickets/#{@ticket_id}/time_tracking/resume"
      dataType:    'json'
      processData: true
      # Ver comentário em startTracking: 409 é tratada localmente.
      failResponseNoTrigger: true
      success:     (data) =>
        @tracking = data
        @totalSeconds = @baseSeconds(data, @totalSeconds)
        @isPaused = false
        @startTimer(data.resumed_at || data.started_at)
        @updateButtonStates()
        @notify(
          type:    'success'
          msg:     App.i18n.translateContent('Contagem retomada')
          timeout: 2000
        )
      error: (xhr) =>
        @updateButtonStates()
        # Parse JSON response if not already parsed
        responseData = xhr.responseJSON
        if !responseData && xhr.responseText
          try
            responseData = JSON.parse(xhr.responseText)
          catch e
            responseData = {}
        
        # Check for existing ticket - show switch dialog instead of error
        if responseData?.existing_ticket_id
          @showSwitchDialog(responseData)
          return

        @notify(
          type:    'error'
          msg:     responseData?.error || App.i18n.translateContent('Erro ao retomar contagem')
          timeout: 3000
        )
    )

  showSwitchDialog: (data) ->
    existingNumber = data.existing_ticket_number || data.existing_ticket_id
    
    new App.ControllerConfirm(
      head: App.i18n.translateContent('Outro ticket em atendimento')
      message: App.i18n.translateContent('Você já está atendendo o ticket #%s. Deseja pausar esse ticket e iniciar a contagem neste?', existingNumber)
      buttonClass: 'btn--primary'
      buttonSubmit: App.i18n.translateContent('Sim, pausar e iniciar')
      buttonCancel: App.i18n.translateContent('Não')
      container: @el.closest('.content')
      callback: =>
        @switchTracking(data.existing_ticket_id)
    )

  switchTracking: (fromTicketId) ->
    @ajax(
      id:          "tt_switch_#{@ticket_id}"
      type:        'POST'
      url:         "#{@apiPath}/tickets/#{@ticket_id}/time_tracking/switch"
      data:        JSON.stringify(
        from_ticket_id: fromTicketId
      )
      processData: false
      contentType: 'application/json'
      success:     (data) =>
        @tracking = data.new_tracking
        @totalSeconds = @baseSeconds(@tracking)
        @isPaused = false
        @startTimer(@tracking.resumed_at || @tracking.started_at)
        @updateButtonStates()
        @notify(
          type:    'success'
          msg:     App.i18n.translateContent('Contagem transferida para este ticket')
          timeout: 2000
        )
      error: (xhr) =>
        @updateButtonStates()
        @notify(
          type:    'error'
          msg:     xhr.responseJSON?.error || App.i18n.translateContent('Erro ao transferir contagem')
          timeout: 3000
        )
    )

  # Auto-pause when user goes offline or enters pause
  onUserStateChanged: =>
    @currentUser = App.User.current()
    
    if @tracking?.is_active && !@isPaused
      if @currentUser.current_state == 'offline' || @currentUser.in_pause
        @autoPauseTracking()
    @checkCurrentTracking()
    @updateButtonStates()

  onPauseStarted: =>
    @currentUser = App.User.current()
    
    if @tracking?.is_active && !@isPaused
      @autoPauseTracking()
    
    @updateButtonStates()

  onPauseEnded: =>
    @currentUser = App.User.current()
    @updateButtonStates()

  onPauseControlLogout: =>
    if @tracking?.is_active && !@isPaused
      @autoPauseTracking()
    @checkCurrentTracking()
    @updateButtonStates()

  onPauseControlLogin: =>
    @checkCurrentTracking()
    @updateButtonStates()

  # WebSocket event: Time tracking state changed (from any source)
  onTimeTrackingStateChange: (data) =>
    return if !data
    return if data.ticket_id != @ticket_id
    return if data.user_id != @currentUser.id
    
    # Update local state from server data
    @tracking = {
      id: data.id
      ticket_id: data.ticket_id
      user_id: data.user_id
      is_active: data.is_active
      started_at: data.started_at
      paused_at: data.paused_at
      resumed_at: data.resumed_at
      ended_at: data.ended_at
      total_seconds: data.total_seconds
      ticket_total_seconds: data.ticket_total_seconds
    }
    @totalSeconds = @baseSeconds(data)
    
    switch data.current_state
      when 'running'
        @isPaused = false
        @isDeactivated = false
        @startTimer(data.resumed_at || data.started_at)
      when 'paused'
        @isPaused = true
        @isDeactivated = !data.is_active
        @stopTimer()
      when 'ended', 'inactive'
        @tracking = null
        @isPaused = false
        @isDeactivated = false
        @stopTimer()
        @totalSeconds = 0
    
    @updateButtonStates()
    @renderTime()

  # WebSocket event: Time tracking destroyed
  onTimeTrackingDestroyed: (data) =>
    return if !data
    return if data.ticket_id != @ticket_id
    return if data.user_id != @currentUser.id
    
    @tracking = null
    @totalSeconds = 0
    @isPaused = false
    @isDeactivated = false
    @stopTimer()
    @updateButtonStates()

  # WebSocket event: Ticket time tracking changed (broadcast to all viewers)
  onTicketTimeTrackingChange: (data) =>
    return if !data
    return if data.ticket_id != @ticket_id
    
    # If this is for another user, just refresh the display
    if data.user_id != @currentUser.id
      # Could show indicator that another agent is working on this ticket
      return
    
    # For current user, handled by onTimeTrackingStateChange
    @checkCurrentTracking()

  # WebSocket event: New time tracking created
  onTimeTrackingCreated: (data) =>
    return if !data
    # Check if this affects current ticket for current user
    @checkCurrentTracking()

  # WebSocket event: Time tracking updated
  onTimeTrackingUpdated: (data) =>
    return if !data
    # Check if this affects current ticket for current user  
    @checkCurrentTracking()

  autoPauseTracking: ->
    return if !@tracking?.is_active
    return if @isPaused
    
    @ajax(
      id:          "tt_autopause_#{@ticket_id}"
      type:        'POST'
      url:         "#{@apiPath}/tickets/#{@ticket_id}/time_tracking/pause"
      processData: true
      success:     (data) =>
        @tracking = data
        @totalSeconds = @baseSeconds(data, @totalSeconds)
        @isPaused = true
        @stopTimer()
        @updateButtonStates()
        @renderTime()
      error: =>
        # Silent error for auto-pause
    )

  onTicketUpdate: (data) =>
    return if data.ticket_id != @ticket_id
    
    # Reload ticket state
    oldState = @ticket.state?.name
    @ticket = App.Ticket.find(@ticket_id)
    newState = @ticket.state?.name
    
    # If ticket was just closed, stop the timer and refresh tracking state
    if oldState != 'closed' && newState == 'closed'
      @stopTimer()
      @checkCurrentTracking() # Refresh to get paused state from server
    # If ticket was reopened, allow resuming
    else if oldState == 'closed' && newState != 'closed'
      @checkCurrentTracking() # Refresh to check if there's a paused tracking to resume
    
    @updateButtonStates()

  onTicketStateChange: =>
    # Ensure player updates without full page reload
    @checkCurrentTracking()
    @updateButtonStates()

  onTicketLoaded: (data) =>
    return if data?.ticket_id? && data.ticket_id != @ticket_id
    @ticket = App.Ticket.find(@ticket_id) || @ticket
    @checkCurrentTracking()
    @updateButtonStates()

  # Timer functions
  startTimer: (startAt = null) ->
    @stopTimer()
    @timerStartedAt = if startAt then new Date(startAt) else new Date()
    @timer = setInterval(=>
      @renderTime()
    , 1000)

  stopTimer: ->
    if @timer
      clearInterval(@timer)
      @timer = null
    @timerStartedAt = null

  renderTime: ->
    return if !@timerDisplay

    if @isPaused || !@timerStartedAt
      # Show stored total
      totalSeconds = @totalSeconds
    else
      # Calculate running total
      now = new Date()
      elapsed = Math.floor((now - @timerStartedAt) / 1000)
      totalSeconds = @totalSeconds + elapsed

    hours = Math.floor(totalSeconds / 3600)
    minutes = Math.floor((totalSeconds % 3600) / 60)
    seconds = totalSeconds % 60

    pad = (n) -> if n < 10 then "0#{n}" else "#{n}"
    
    @timerDisplay.text("#{pad(hours)}:#{pad(minutes)}:#{pad(seconds)}")

  release: ->
    @stopTimer()
    @closeOthers()
    @ticket.off('change:state_id', @onTicketStateChange)
    @controllerUnbind('ui::ticket::all::loaded', @onTicketLoaded)
    @controllerUnbind('ui::ticket::load', @onTicketLoaded)
    @controllerUnbind('TicketTimeTracking:stateChange', @onTimeTrackingStateChange)
    @controllerUnbind('TicketTimeTracking:destroyed', @onTimeTrackingDestroyed)
    @controllerUnbind('Ticket:timeTrackingChange', @onTicketTimeTrackingChange)
    @controllerUnbind('TicketTimeTracking:create', @onTimeTrackingCreated)
    @controllerUnbind('TicketTimeTracking:update', @onTimeTrackingUpdated)
    super
