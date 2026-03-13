# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# User Status Bar - A fixed bar at the top showing user state (online/offline/pause)
class App.UserStatusBar extends App.Controller

  constructor: ->
    super
    @currentUser = App.User.current()
    return if !@currentUser?.permission('user.pause_control')

    @pauseTypes = []
    @currentState = 'offline'
    @currentPause = null
    @isLoggedIn = false
    @elapsedTimer = null
    @skipNextCurrentCheck = false
    @loginInProgress = false
    @actionInProgress = false  # startPause, endPause, setState
    @_renderTimer = null
    @_checkPauseTimer = null

    # Load data
    @loadPauseTypes()
    @checkPauseLogin()

    # Listen for state changes (skip refetch when we just updated from our own start/end)
    @controllerBind('user_state:changed', =>
      if @skipNextCurrentCheck
        @skipNextCurrentCheck = false
        return
      @scheduleCheckCurrentPause()
    )

    # Quando o blocker (ou outro) encerra a pausa, atualizar estado na hora para não precisar de segundo clique
    @controllerBind('pause:ended', =>
      @currentPause = null
      @currentState = 'online'
      @stopElapsedTimer()
      App.User.current().in_pause = false
      App.User.current().current_state = 'online'
      @skipNextCurrentCheck = true
      @render()
    )

    # Check pause time limit periodically (só quando em pausa, intervalo maior para reduzir carga)
    @timer = setInterval(=>
      @checkPauseTimeLimit() if @currentPause?.active
    , 60000)

  scheduleRender: (immediate = false) ->
    if immediate
      clearTimeout(@_renderTimer) if @_renderTimer
      @_renderTimer = null
      @render()
      return
    return if @_renderTimer
    @_renderTimer = setTimeout(=>
      @_renderTimer = null
      @render()
    , 120)

  scheduleCheckCurrentPause: ->
    return if !@isLoggedIn
    clearTimeout(@_checkPauseTimer) if @_checkPauseTimer
    @_checkPauseTimer = setTimeout(=>
      @_checkPauseTimer = null
      @checkCurrentPause()
    , 200)

  loadPauseTypes: ->
    @ajax(
      id:          'status_bar_pause_types'
      type:        'GET'
      url:         "#{@apiPath}/pause_types"
      processData: true
      success:     (data) =>
        if Array.isArray(data)
          @pauseTypes = data.filter((p) -> p.active)
        else
          @pauseTypes = []
        @scheduleRender()
      error: =>
        @pauseTypes = []
        @scheduleRender()
    )

  checkPauseLogin: ->
    @ajax(
      id:          'status_bar_login_state'
      type:        'GET'
      url:         "#{@apiPath}/user_pause_sessions/current"
      processData: true
      success:     (data) =>
        @isLoggedIn = !!data?.logged_in
        App.Config.set('pause_control_logged_in', @isLoggedIn)
        if @isLoggedIn
          @checkCurrentPause()
        else
          @currentPause = null
          @stopElapsedTimer()
          @getCurrentState()
          @scheduleRender()
      error: =>
        @isLoggedIn = false
        App.Config.set('pause_control_logged_in', false)
        @currentPause = null
        @stopElapsedTimer()
        @getCurrentState()
        @scheduleRender()
    )

  checkCurrentPause: ->
    return @render() if !@isLoggedIn

    @ajax(
      id:          'status_bar_current_pause'
      type:        'GET'
      url:         "#{@apiPath}/user_pauses/current"
      processData: true
      success:     (data) =>
        if data && data.id && data.active != false
          @currentState = 'pause'
          @currentPause = data
          @currentPause.active = true
          App.User.current().in_pause = true
          App.User.current().current_state = 'pause'
          @startElapsedTimer()
        else
          @currentPause = null
          @stopElapsedTimer()
          App.User.current().in_pause = false
          @currentState = 'online'
          @getCurrentState()
        @scheduleRender()
      error: =>
        @currentPause = null
        @stopElapsedTimer()
        App.User.current().in_pause = false
        @currentState = 'online'
        @getCurrentState()
        @scheduleRender()
    )

  getCurrentState: ->
    @ajax(
      id:          'status_bar_current_state'
      type:        'GET'
      url:         "#{@apiPath}/user_states/current"
      processData: true
      success:     (data) =>
        @currentState = data?.state || 'offline'
        App.User.current().current_state = @currentState
        @scheduleRender()
      error: =>
        @currentState = 'offline'
        App.User.current().current_state = 'offline'
        @scheduleRender()
    )

  loginControl: (e) =>
    e?.preventDefault()
    e?.stopPropagation()
    return if @loginInProgress

    @loginInProgress = true
    @scheduleRender(true)

    @ajax(
      id:          'status_bar_login'
      type:        'POST'
      url:         "#{@apiPath}/user_pause_sessions/login"
      processData: true
      timeout:     60000
      success:     (data) =>
        @loginInProgress = false
        @isLoggedIn = true
        App.Config.set('pause_control_logged_in', true)
        App.Event.trigger('pause_control:login')
        @checkCurrentPause()
      error: (xhr) =>
        @loginInProgress = false
        @scheduleRender(true)
        @notify(
          type:    'error'
          msg:     xhr.responseJSON?.error || App.i18n.translateContent('Falha ao efetuar login no controle de pausas')
          timeout: 3000
        )
    )

  logoutControl: (e) =>
    e?.preventDefault()
    e?.stopPropagation()
    @closeDropdown()

    @ajax(
      id:          'status_bar_logout'
      type:        'POST'
      url:         "#{@apiPath}/user_pause_sessions/logout"
      processData: true
      timeout:     60000
      success:     (data) =>
        @isLoggedIn = false
        App.Config.set('pause_control_logged_in', false)
        @currentPause = null
        @stopElapsedTimer()
        @getCurrentState()
        @scheduleRender()
        @skipNextCurrentCheck = true
        App.Event.trigger('pause_control:logout')
        App.Event.trigger('user_state:changed')
      error: (xhr) =>
        @notify(
          type:    'error'
          msg:     xhr.responseJSON?.error || App.i18n.translateContent('Falha ao efetuar logout no controle de pausas')
          timeout: 3000
        )
    )

  setOffline: (e) =>
    e?.preventDefault()
    e?.stopPropagation()
    @closeDropdown()
    @setState('offline')

  setOnline: (e) =>
    e?.preventDefault()
    e?.stopPropagation()
    @closeDropdown()
    @setState('online')

  selectPause: (e) =>
    e?.preventDefault()
    e?.stopPropagation()
    @closeDropdown()
    pauseTypeId = $(e.currentTarget).data('pause-type-id')
    @startPause(pauseTypeId)

  endPauseClick: (e) =>
    e?.preventDefault()
    e?.stopPropagation()
    if @isTimeExceeded()
      reason = @el.find('.js-delay-reason').val()?.trim()
      if !reason
        @notify(
          type:    'error'
          msg:     App.i18n.translateContent('Por favor, informe a justificativa do atraso.')
          timeout: 3000
        )
        @el.find('.js-delay-reason').focus()
        return
      @closeDropdown()
      @endPause(reason)
    else
      @closeDropdown()
      @endPause()

  toggleDropdown: (e) =>
    e?.preventDefault()
    e?.stopPropagation()
    @$('.js-status-dropdown').toggleClass('is-open')

  closeDropdown: ->
    @$('.js-status-dropdown').removeClass('is-open')

  setState: (state) ->
    return if !@isLoggedIn
    return if @currentPause?.active

    @ajax(
      id:          'status_bar_set_state'
      type:        'POST'
      url:         "#{@apiPath}/user_states/set"
      data:        JSON.stringify(state: state)
      processData: false
      contentType: 'application/json'
      timeout:     60000
      success:     (data) =>
        @currentState = data.state
        App.User.current().current_state = data.state
        @scheduleRender()
        @skipNextCurrentCheck = true
        App.Event.trigger('user_state:changed')
      error: (xhr) =>
        @notify(
          type:    'error'
          msg:     xhr.responseJSON?.error || App.i18n.translateContent('Failed to update state')
          timeout: 3000
        )
    )

  startPause: (pauseTypeId) ->
    return if !@isLoggedIn
    return if @currentPause?.active

    # Otimista: mostra pausa e inicia contagem na hora (usuário não perde tempo esperando a rede)
    startedAt = new Date().toISOString()
    optimisticPause =
      id:             null
      pause_type_id:  parseInt(pauseTypeId, 10)
      started_at:     startedAt
      created_at:     startedAt
      active:         true
    @currentState = 'pause'
    @currentPause = optimisticPause
    App.User.current().in_pause = true
    App.User.current().current_state = 'pause'
    @startElapsedTimer()
    @scheduleRender(true)
    @skipNextCurrentCheck = true
    App.Event.trigger('user_state:changed')
    App.Event.trigger('pause:started', optimisticPause)

    @ajax(
      id:          'status_bar_start_pause'
      type:        'POST'
      url:         "#{@apiPath}/user_pauses/start"
      data:        JSON.stringify(pause_type_id: pauseTypeId, started_at: startedAt)
      processData: false
      contentType: 'application/json'
      timeout:     60000
      success:     (data) =>
        # Mantém started_at otimista se for anterior à resposta do servidor
        if data.started_at && @currentPause
          serverStarted = new Date(data.started_at).getTime()
          clientStarted = new Date(@currentPause.started_at).getTime()
          data.started_at = @currentPause.started_at if clientStarted < serverStarted
        @currentPause = data
        @currentPause.active = true
        App.User.current().in_pause = true
        @scheduleRender()
        App.Event.trigger('pause:started', @currentPause)
      error: (xhr) =>
        @currentState = 'online'
        @currentPause = null
        @stopElapsedTimer()
        App.User.current().in_pause = false
        App.User.current().current_state = 'online'
        @scheduleRender(true)
        App.Event.trigger('user_state:changed')
        App.Event.trigger('pause:ended')
        @notify(
          type:    'error'
          msg:     xhr.responseJSON?.error || App.i18n.translateContent('Failed to start pause')
          timeout: 3000
        )
    )

  endPause: (delayReason = null) ->
    return if !@isLoggedIn
    return if !@currentPause?.active

    # Otimista: para o timer e mostra "online" na hora (não penaliza por rede lenta ou queda)
    endedAt = new Date().toISOString()
    @currentState = 'online'
    @currentPause = null
    @exceededRendered = false
    @stopElapsedTimer()
    App.User.current().in_pause = false
    App.User.current().current_state = 'online'
    @scheduleRender(true)
    @skipNextCurrentCheck = true
    App.Event.trigger('user_state:changed')
    App.Event.trigger('pause:ended')

    payload = delay_reason: delayReason, ended_at: endedAt
    @ajax(
      id:          'status_bar_end_pause'
      type:        'POST'
      url:         "#{@apiPath}/user_pauses/end"
      data:        JSON.stringify(payload)
      processData: false
      contentType: 'application/json'
      timeout:     60000
      success:     (data) =>
        @notify(
          type:    'success'
          msg:     App.i18n.translateContent('Pausa finalizada.')
          timeout: 2000
        )
      error: (xhr) =>
        @notify(
          type:    'error'
          msg:     xhr.responseJSON?.error || App.i18n.translateContent('Falha ao finalizar pausa. Verifique a conexão.')
          timeout: 5000
        )
        @checkCurrentPause()
    )

  checkPauseTimeLimit: ->
    return if !@currentPause?.active

    @ajax(
      id:          'status_bar_check_time_limit'
      type:        'GET'
      url:         "#{@apiPath}/user_pauses/check_time_limit"
      processData: true
      success:     (data) =>
        if data.exceeded
          App.Event.trigger('pause:time_exceeded')
      error: ->
        # Silent error
    )

  pauseStartedAt: ->
    raw = @currentPause?.started_at || @currentPause?.created_at
    return null if !raw

    if typeof raw is 'number'
      ms = if raw < 1000000000000 then raw * 1000 else raw
      return new Date(ms)

    d = new Date(raw)
    return null if isNaN(d.getTime())
    d

  formatDuration: (seconds) ->
    seconds = Math.max(0, Math.floor(seconds || 0))
    h = Math.floor(seconds / 3600)
    m = Math.floor((seconds % 3600) / 60)
    s = seconds % 60
    pad = (n) -> (if n < 10 then "0#{n}" else "#{n}")
    if h > 0 then "#{h}:#{pad(m)}:#{pad(s)}" else "#{pad(m)}:#{pad(s)}"

  updateElapsed: ->
    $target = @$('.js-pause-elapsed')
    if @currentState isnt 'pause' || !@currentPause?.active
      @exceededRendered = false
      $target?.text('')
      return

    startedAt = @pauseStartedAt()
    if !startedAt
      $target?.text('')
      return

    now = new Date()
    diffSeconds = (now.getTime() - startedAt.getTime()) / 1000
    $target?.text(@formatDuration(diffSeconds))

    # Ao ultrapassar o tempo limite, re-renderiza para exibir o campo de justificativa (uma vez)
    if @isTimeExceeded() && !@exceededRendered
      @exceededRendered = true
      @scheduleRender(true)

  startElapsedTimer: ->
    return if @elapsedTimer
    @elapsedTimer = setInterval((=> @updateElapsed()), 1000)
    # Quando a aba fica em segundo plano, pausar o timer para economizar CPU (Chrome)
    @_visibilityHandler = => @onVisibilityChange()
    $(document).on('visibilitychange.statusbar', @_visibilityHandler)

  onVisibilityChange: ->
    if document.hidden
      if @elapsedTimer
        clearInterval(@elapsedTimer)
        @elapsedTimer = null
    else
      return unless @currentState is 'pause' and @currentPause?.active
      return if @elapsedTimer
      @elapsedTimer = setInterval((=> @updateElapsed()), 1000)
      @updateElapsed()

  stopElapsedTimer: ->
    $(document).off('visibilitychange.statusbar', @_visibilityHandler) if @_visibilityHandler
    @_visibilityHandler = null
    return unless @elapsedTimer
    clearInterval(@elapsedTimer)
    @elapsedTimer = null

  getPauseTypeName: ->
    return '' if !@currentPause?.pause_type_id
    pauseType = @pauseTypes.find((p) => p.id == @currentPause.pause_type_id)
    pauseType?.name || ''

  getPauseTypeLimit: ->
    return null if !@currentPause?.pause_type_id
    pauseType = @pauseTypes.find((p) => p.id == @currentPause.pause_type_id)
    pauseType?.time_limit || null

  getElapsedSeconds: ->
    return 0 if !@currentPause?.active
    startedAt = @pauseStartedAt()
    return 0 if !startedAt
    Math.floor((new Date().getTime() - startedAt.getTime()) / 1000)

  isTimeExceeded: ->
    limit = @getPauseTypeLimit()
    return false if !limit? or limit <= 0
    @getElapsedSeconds() > (limit * 60)

  buildStatusDot: (type, label = null) ->
    cssClass = switch type
      when 'online' then 'status-dot status-dot--online'
      when 'offline' then 'status-dot status-dot--offline'
      when 'pause' then 'status-dot status-dot--pause'
      else 'status-dot'
    if label?
      "<span class=\"#{cssClass}\">#{label}</span>"
    else
      "<span class=\"#{cssClass}\"></span>"

  render: ->
    # Remove existing bar
    $('.user-status-bar').remove()

    # Build HTML
    html = @buildHtml()

    # Insert at top of body, after navigation
    $('body').prepend(html)

    # Add class to body for layout adjustment
    $('body').addClass('has-status-bar')

    # Bind events
    @el = $('.user-status-bar')
    @el.find('.js-status-toggle').on('click', @toggleDropdown)
    @el.find('.js-set-offline').on('click', @setOffline)
    @el.find('.js-set-online').on('click', @setOnline)
    @el.find('.js-select-pause').on('click', @selectPause)
    @el.find('.js-end-pause').on('click', @endPauseClick)
    @el.find('.js-status-login').on('click', @loginControl)
    @el.find('.js-status-logout').on('click', @logoutControl)

    # Close dropdown when clicking outside
    $(document).off('click.statusbar').on('click.statusbar', (e) =>
      if !$(e.target).closest('.user-status-bar').length
        @closeDropdown()
    )

    # Update elapsed time
    @updateElapsed()

  buildHtml: ->
    stateText = switch @currentState
      when 'online' then App.i18n.translateContent('Online')
      when 'pause'
        pauseName = @getPauseTypeName()
        if pauseName then pauseName else App.i18n.translateContent('Em Pausa')
      else App.i18n.translateContent('Offline')

    pauseLimit = @getPauseTypeLimit()
    stateIcon = switch @currentState
      when 'online' then @buildStatusDot('online')
      when 'pause' then @buildStatusDot('pause', if pauseLimit? then pauseLimit else '')
      else @buildStatusDot('offline')

    # Quando em pausa ativa: dropdown mostra só "Sair da Pausa" (e justificativa se tempo excedido)
    inActivePause = @currentPause?.active
    if inActivePause
      exceededHtml = ''
      if @isTimeExceeded()
        exceededHtml = """
          <div class="status-dropdown-exceeded">
            <div class="status-dropdown-exceeded-text">#{App.i18n.translateContent('Tempo limite excedido!')}</div>
            <label for="status-bar-delay-reason" class="status-dropdown-exceeded-label">#{App.i18n.translateContent('Justificativa (obrigatória)')}</label>
            <textarea id="status-bar-delay-reason" class="form-control form-control--small js-delay-reason status-dropdown-reason" rows="2" placeholder="#{App.i18n.translateContent('Informe o motivo do atraso...')}"></textarea>
          </div>
        """
      endPauseOption = """
        <div class="status-dropdown-divider"></div>
        #{exceededHtml}
        <a href="#" class="status-dropdown-item status-dropdown-item--center js-end-pause status-dropdown-item--action">
          <span class="status-dropdown-item-name">#{App.i18n.translateContent('Sair da Pausa')}</span>
        </a>
      """
      pauseOptions = ''
      logoutOption = ''
    else
      # Fora da pausa: lista de pausas, offline, online e finalizar
      pauseOptions = ''
      if @pauseTypes.length > 0
        pauseOptions = '<div class="status-dropdown-divider"></div>'
        pauseOptions += "<div class=\"status-dropdown-header\">#{App.i18n.translateContent('Pausas')}</div>"
        for pauseType in @pauseTypes
          isActive = @currentState == 'pause' && @currentPause?.pause_type_id == pauseType.id
          activeClass = if isActive then 'is-active' else ''
          pauseLimitLabel = if pauseType.time_limit? then pauseType.time_limit else ''
          pauseOptions += """
            <a href="#" class="status-dropdown-item js-select-pause #{activeClass}" data-pause-type-id="#{pauseType.id}">
              #{@buildStatusDot('pause', pauseLimitLabel)}
              <span class="status-dropdown-item-name">#{App.Utils.htmlEscape(pauseType.name)}</span>
              #{if isActive then App.Utils.icon('checkmark', 'status-dropdown-check') else ''}
            </a>
          """
      endPauseOption = ''
      logoutOption = ''
      if @isLoggedIn
        logoutOption = """
          <div class="status-dropdown-divider"></div>
          <a href="#" class="status-dropdown-item js-status-logout status-dropdown-item--action">
            #{App.Utils.icon('external', 'status-dropdown-icon')}
            <span class="status-dropdown-item-name">#{App.i18n.translateContent('Finalizar')}</span>
          </a>
        """

    # Elapsed time badge
    elapsedBadge = ''
    if @currentState == 'pause' && @currentPause?.active
      elapsedBadge = '<span class="status-bar-elapsed js-pause-elapsed"></span>'

    if !@isLoggedIn
      loginBtnDisabled = if @loginInProgress then 'disabled' else ''
      loginBtnText = if @loginInProgress then App.i18n.translateContent('Carregando...') else App.i18n.translateContent('Iniciar')
      return """
        <div class="user-status-bar">
          <div class="status-bar-container">
            <div class="status-bar-title">#{App.i18n.translateContent('Controle de pausas')}</div>
            <button type="button" class="status-bar-login js-status-login" #{loginBtnDisabled}>
              #{loginBtnText}
            </button>
          </div>
        </div>
      """

    dropdownContent = if inActivePause
      endPauseOption
    else
      """
        <a href="#" class="status-dropdown-item js-set-offline #{if @currentState == 'offline' then 'is-active' else ''}">
          #{@buildStatusDot('offline')}
          <span class="status-dropdown-item-name">#{App.i18n.translateContent('Offline')}</span>
          #{if @currentState == 'offline' then App.Utils.icon('checkmark', 'status-dropdown-check') else ''}
        </a>
        <a href="#" class="status-dropdown-item js-set-online #{if @currentState == 'online' then 'is-active' else ''}">
          #{@buildStatusDot('online')}
          <span class="status-dropdown-item-name">#{App.i18n.translateContent('Online')}</span>
          #{if @currentState == 'online' then App.Utils.icon('checkmark', 'status-dropdown-check') else ''}
        </a>
        #{pauseOptions}
        #{endPauseOption}
        #{logoutOption}
      """

    """
      <div class="user-status-bar">
        <div class="status-bar-container">
          <div class="status-bar-title">#{App.i18n.translateContent('Controle de pausas')}</div>
          <div class="status-bar-indicator js-status-dropdown">
            <button type="button" class="status-bar-toggle js-status-toggle">
              #{stateIcon}
              <span class="status-bar-text">#{stateText}</span>
              #{elapsedBadge}
              #{App.Utils.icon('arrow-down', 'status-bar-arrow')}
            </button>
            <div class="status-dropdown">
              #{dropdownContent}
            </div>
          </div>
        </div>
      </div>
    """

  release: ->
    clearTimeout(@_renderTimer) if @_renderTimer
    @_renderTimer = null
    clearTimeout(@_checkPauseTimer) if @_checkPauseTimer
    @_checkPauseTimer = null
    if @timer
      clearInterval(@timer)
      @timer = null
    @stopElapsedTimer()
    $('.user-status-bar').remove()
    $('body').removeClass('has-status-bar')
    $(document).off('click.statusbar')
    super

# Initialize as a plugin
App.Config.set('user_status_bar', App.UserStatusBar, 'Plugins')

