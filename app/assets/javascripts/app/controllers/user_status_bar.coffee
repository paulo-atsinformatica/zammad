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

    # Load data
    @loadPauseTypes()
    @checkPauseLogin()

    # Listen for state changes
    @controllerBind('user_state:changed', =>
      @checkCurrentPause()
    )

    # Check pause time limit periodically
    @timer = setInterval(=>
      @checkPauseTimeLimit()
    , 30000)

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
        @render()
      error: =>
        @pauseTypes = []
        @render()
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
          @render()
      error: =>
        @isLoggedIn = false
        App.Config.set('pause_control_logged_in', false)
        @currentPause = null
        @stopElapsedTimer()
        @getCurrentState()
        @render()
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
          # Get current state from user
          @getCurrentState()
        @render()
      error: =>
        @currentPause = null
        @stopElapsedTimer()
        App.User.current().in_pause = false
        @getCurrentState()
        @render()
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
        @render()
      error: =>
        @currentState = 'offline'
        App.User.current().current_state = 'offline'
        @render()
    )

  loginControl: (e) =>
    e?.preventDefault()
    e?.stopPropagation()

    @ajax(
      id:          'status_bar_login'
      type:        'POST'
      url:         "#{@apiPath}/user_pause_sessions/login"
      processData: true
      success:     (data) =>
        @isLoggedIn = true
        App.Config.set('pause_control_logged_in', true)
        App.Event.trigger('pause_control:login')
        @checkCurrentPause()
      error: (xhr) =>
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
      success:     (data) =>
        @isLoggedIn = false
        App.Config.set('pause_control_logged_in', false)
        @currentPause = null
        @stopElapsedTimer()
        @getCurrentState()
        @render()
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
      success:     (data) =>
        @currentState = data.state
        App.User.current().current_state = data.state
        @render()
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

    @ajax(
      id:          'status_bar_start_pause'
      type:        'POST'
      url:         "#{@apiPath}/user_pauses/start"
      data:        JSON.stringify(pause_type_id: pauseTypeId)
      processData: false
      contentType: 'application/json'
      success:     (data) =>
        @currentState = 'pause'
        @currentPause = data
        @currentPause.active = true
        App.User.current().in_pause = true
        App.User.current().current_state = 'pause'
        @startElapsedTimer()
        @render()
        App.Event.trigger('user_state:changed')
        App.Event.trigger('pause:started')
      error: (xhr) =>
        @notify(
          type:    'error'
          msg:     xhr.responseJSON?.error || App.i18n.translateContent('Failed to start pause')
          timeout: 3000
        )
    )

  endPause: (delayReason = null) ->
    return if !@isLoggedIn
    return if !@currentPause?.active

    @ajax(
      id:          'status_bar_end_pause'
      type:        'POST'
      url:         "#{@apiPath}/user_pauses/end"
      data:        JSON.stringify(delay_reason: delayReason)
      processData: false
      contentType: 'application/json'
      success:     (data) =>
        @currentState = 'online'
        @currentPause = null
        @stopElapsedTimer()
        App.User.current().in_pause = false
        App.User.current().current_state = 'online'
        @render()
        App.Event.trigger('user_state:changed')
        App.Event.trigger('pause:ended')
      error: (xhr) =>
        @notify(
          type:    'error'
          msg:     xhr.responseJSON?.error || App.i18n.translateContent('Failed to end pause')
          timeout: 3000
        )
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
    return if !$target?.length

    if @currentState isnt 'pause' || !@currentPause?.active
      $target.text('')
      return

    startedAt = @pauseStartedAt()
    return $target.text('') if !startedAt

    now = new Date()
    diffSeconds = (now.getTime() - startedAt.getTime()) / 1000
    $target.text(@formatDuration(diffSeconds))

  startElapsedTimer: ->
    return if @elapsedTimer
    @elapsedTimer = setInterval((=> @updateElapsed()), 1000)

  stopElapsedTimer: ->
    return if !@elapsedTimer
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

    # Build pause options
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

    # End pause option
    endPauseOption = ''
    if @currentPause?.active
      endPauseOption = """
        <div class="status-dropdown-divider"></div>
        <a href="#" class="status-dropdown-item status-dropdown-item--center js-end-pause status-dropdown-item--action">
          <span class="status-dropdown-item-name">#{App.i18n.translateContent('Sair da Pausa')}</span>
        </a>
      """

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
      return """
        <div class="user-status-bar">
          <div class="status-bar-container">
            <div class="status-bar-title">#{App.i18n.translateContent('Controle de pausas')}</div>
            <button type="button" class="status-bar-login js-status-login">
              #{App.i18n.translateContent('Iniciar')}
            </button>
          </div>
        </div>
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
            </div>
          </div>
        </div>
      </div>
    """

  release: ->
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

