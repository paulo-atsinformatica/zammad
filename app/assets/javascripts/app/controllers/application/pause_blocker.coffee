class App.ApplicationPauseBlocker extends App.Controller
  constructor: ->
    super
    # Ensure element is hidden by default and has correct class
    if @el && !@el.hasClass('pause-blocker-overlay')
      @el.addClass('pause-blocker-overlay')
    @el.hide() if @el
    @checkPause()
    @setupListeners()

  setupListeners: ->
    @controllerBind('pause:started', =>
      @showBlocker()
    )
    @controllerBind('pause:ended', =>
      @hideBlocker()
    )
    @controllerBind('user_state:changed', =>
      @checkPause()
    )

  checkPause: ->
    user = App.User.current()
    if user && user.in_pause
      @showBlocker()
    else
      @hideBlocker()

  showBlocker: ->
    return if @blockerVisible

    user = App.User.current()
    return if !user || !user.in_pause

    pause = user.active_pause
    return if !pause

    @blockerVisible = true
    @el.show() # Explicitly show the element
    @html App.view('application/pause_blocker')(
      pause: pause
      pauseType: pause.pause_type
    )

    # Block all interactions except the exit button
    @el.on('click', '.js-exit-pause', (e) =>
      e.stopPropagation()
      @exitPause()
    )

    # Prevent all other clicks
    @el.on('click', (e) =>
      return if $(e.target).closest('.js-exit-pause').length > 0
      e.preventDefault()
      e.stopPropagation()
    )

    # Block form submissions
    $(document).on('submit.pause_blocker', 'form', (e) =>
      e.preventDefault()
      e.stopPropagation()
      @notify(
        type:    'error'
        msg:     __('Cannot perform actions while in pause')
        timeout: 3000
      )
    )

    # Block keyboard shortcuts
    $(document).on('keydown.pause_blocker', (e) =>
      # Allow only Escape key to potentially exit
      return if e.keyCode == 27
      e.preventDefault()
      e.stopPropagation()
    )

  hideBlocker: ->
    return if !@blockerVisible

    @blockerVisible = false
    @el.empty()
    @el.hide() # Explicitly hide the element

    # Remove event handlers
    $(document).off('submit.pause_blocker')
    $(document).off('keydown.pause_blocker')

  exitPause: ->
    # Check if time limit was exceeded
    user = App.User.current()
    pause = user.active_pause

    if pause && pause.exceeded_time_limit
      # Show delay reason modal
      new App.UserPauseDelayReasonDialog(
        container: @el.closest('.content')
        callback: (delayReason) =>
          @endPause(delayReason)
      )
    else
      @endPause()

  endPause: (delayReason = null) ->
    @ajax(
      id:          'user_pause_end'
      type:        'POST'
      url:         "#{@apiPath}/user_pauses/end"
      data:        JSON.stringify(delay_reason: delayReason)
      processData: false
      contentType: 'application/json'
      success:     (data, status, xhr) =>
        App.User.current().current_state = 'online'
        App.User.current().in_pause = false
        @hideBlocker()
        @controllerTrigger('pause:ended')
        @controllerTrigger('user_state:changed')
      error: (xhr) =>
        @notify(
          type:    'error'
          msg:     xhr.responseJSON?.error || __('Failed to end pause')
          timeout: 5000
        )
    )



