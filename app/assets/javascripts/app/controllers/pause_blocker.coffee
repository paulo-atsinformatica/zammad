# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# Pause Blocker - Blocks the entire UI when user is in pause
class App.PauseBlocker extends App.Controller

  constructor: ->
    super
    @currentUser = App.User.current()
    return if !@currentUser?.permission('user.pause_control')

    @currentPause = null
    @pauseType = null
    @elapsedTimer = null
    @timeExceeded = false

    # Check current pause status on load
    @checkCurrentPause()

    # Listen for pause events
    @controllerBind('pause:started', (data) =>
      if data && (data.id || data.started_at) && data.active != false
        @currentPause = data
        @currentPause.active = true
        @show()
      else
        @checkCurrentPause()
    )

    @controllerBind('pause:ended', =>
      @hide()
    )

    @controllerBind('user_state:changed', =>
      return if @visible && @currentPause
      @checkCurrentPause()
    )

    # Periodically check pause status
    @statusTimer = setInterval(=>
      @checkCurrentPause()
    , 30000)

  checkCurrentPause: ->
    return if @visible && @currentPause
    @ajax(
      id:          'pause_blocker_check'
      type:        'GET'
      url:         "#{@apiPath}/user_pauses/current"
      processData: true
      success:     (data) =>
        if data && data.id && data.active != false
          @currentPause = data
          @currentPause.active = true
          @show()
        else
          @currentPause = null
          @hide()
      error: =>
        @currentPause = null
        @hide()
    )

  loadPauseType: ->
    return if !@currentPause?.pause_type_id

    @ajax(
      id:          'pause_blocker_pause_type'
      type:        'GET'
      url:         "#{@apiPath}/pause_types/#{@currentPause.pause_type_id}"
      processData: true
      success:     (data) =>
        @pauseType = data
        # Defer para depois do paint: na 1ª abertura o CSS/cores podem não estar aplicados ainda
        setTimeout (=> @applyPauseTypeColor()), 0
        requestAnimationFrame (=> requestAnimationFrame (=> @applyPauseTypeColor()))
      error: =>
        @pauseType = null
    )

  applyPauseTypeColor: ->
    return if !@pauseType?.color
    color = @pauseType.color
    return if !color

    # Sempre usar o overlay atual no DOM (evita referência obsoleta na 1ª abertura)
    $overlay = $('.pause-blocker-overlay--fullscreen').last()
    return if !$overlay.length
    @$overlay = $overlay

    $overlay.find('.pause-blocker-header').css('background', color)
    $overlay.find('.pause-blocker-modal').css('border-color', color)
    $overlay.find('.pause-blocker-pause-name').css(
      'background': "#{color}20"
      'border': "1px solid #{color}40"
    )
    $overlay.find('.pause-blocker-timer-value').css('color', color)
    $overlay.find('.pause-blocker-footer .btn--primary').css(
      'background': color
      'border-color': color
    )

  show: ->
    return if @visible
    @visible = true
    @render()
    @startElapsedTimer()
    @loadPauseType()

  hide: ->
    return if !@visible
    @visible = false
    @$overlay = null
    @stopElapsedTimer()
    $('.pause-blocker-overlay--fullscreen').remove()
    $('body').removeClass('is-pause-blocked')

  render: ->
    return if !@visible
    return if !@currentPause

    # Remove existing (only our fullscreen overlay)
    $('.pause-blocker-overlay--fullscreen').remove()
    @$overlay = null

    pauseName = @pauseType?.name || App.i18n.translateContent('Pausa')
    timeLimit = @pauseType?.time_limit || @currentPause?.time_limit || 0
    elapsed = @getElapsedSeconds()
    elapsedFormatted = @formatDuration(elapsed)
    
    # Check if time exceeded
    @timeExceeded = timeLimit > 0 && elapsed > (timeLimit * 60)

    exceededClass = if @timeExceeded then 'is-exceeded' else ''
    exceededMessage = if @timeExceeded
      """
        <div class="pause-blocker-exceeded">
          <div class="pause-blocker-exceeded-icon">#{App.Utils.icon('warning', 'icon-warning')}</div>
          <div class="pause-blocker-exceeded-text">#{App.i18n.translateContent('Tempo limite excedido!')}</div>
        </div>
        <div class="pause-blocker-reason">
          <label for="pause-delay-reason">#{App.i18n.translateContent('Justificativa (obrigatória)')}</label>
          <textarea id="pause-delay-reason" class="form-control js-delay-reason" rows="3" placeholder="#{App.i18n.translateContent('Informe o motivo do atraso...')}"></textarea>
        </div>
      """
    else
      ''

    html = """
      <div class="pause-blocker-overlay pause-blocker-overlay--fullscreen #{exceededClass}">
        <div class="pause-blocker-modal">
          <div class="pause-blocker-header">
            <div class="pause-blocker-icon">#{App.Utils.icon('stopwatch', 'icon-pause')}</div>
            <h2 class="pause-blocker-title">#{App.i18n.translateContent('Você está em pausa')}</h2>
          </div>
          <div class="pause-blocker-body">
            <div class="pause-blocker-pause-name">#{App.Utils.htmlEscape(pauseName)}</div>
            <div class="pause-blocker-timer">
              <span class="pause-blocker-timer-label">#{App.i18n.translateContent('Tempo decorrido')}</span>
              <span class="pause-blocker-timer-value js-elapsed-time">#{elapsedFormatted}</span>
            </div>
            #{if timeLimit > 0 then "<div class=\"pause-blocker-limit\">#{App.i18n.translateContent('Limite')}: #{@formatDuration(timeLimit * 60)}</div>" else ''}
            #{exceededMessage}
          </div>
          <div class="pause-blocker-footer">
            <button type="button" class="btn btn--primary btn--large js-end-pause">
              #{App.i18n.translateContent('Sair da Pausa')}
            </button>
          </div>
        </div>
      </div>
    """

    $('body').append(html)
    @$overlay = $('.pause-blocker-overlay--fullscreen').last()
    $('body').addClass('is-pause-blocked')

    # Bind events (only to our overlay)
    @$overlay.find('.js-end-pause').on('click', @endPause)

    if @pauseType?.color
      @applyPauseTypeColor()
      # Segundo frame: garante que cores/CSS apareçam após o primeiro paint
      requestAnimationFrame (=> requestAnimationFrame (=> @applyPauseTypeColor()))

  endPause: (e) =>
    e?.preventDefault()

    # If time exceeded, require reason
    if @timeExceeded
      reason = $('.js-delay-reason').val()?.trim()
      if !reason
        @notify(
          type:    'error'
          msg:     App.i18n.translateContent('Por favor, informe a justificativa do atraso.')
          timeout: 3000
        )
        $('.js-delay-reason').focus()
        return

      @doEndPause(reason)
    else
      @doEndPause(null)

  doEndPause: (delayReason) ->
    # Otimista: para o timer e esconde na hora (não penaliza por rede lenta ou queda)
    endedAt = new Date().toISOString()
    @currentPause = null
    @hide()
    App.Event.trigger('user_state:changed')
    App.Event.trigger('pause:ended')

    payload = delay_reason: delayReason, ended_at: endedAt
    @ajax(
      id:          'pause_blocker_end'
      type:        'POST'
      url:         "#{@apiPath}/user_pauses/end"
      data:        JSON.stringify(payload)
      processData: false
      contentType: 'application/json'
      success:     (data) =>
        @notify(
          type:    'success'
          msg:     App.i18n.translateContent('Pausa finalizada. Você está online.')
          timeout: 3000
        )
      error: (xhr) =>
        @notify(
          type:    'error'
          msg:     xhr.responseJSON?.error || App.i18n.translateContent('Erro ao finalizar pausa. Verifique a conexão e tente novamente.')
          timeout: 5000
        )
        # Re-sincroniza: se o servidor ainda tem a pausa, o overlay volta
        @checkCurrentPause()
    )

  getElapsedSeconds: ->
    return 0 if !@currentPause

    raw = @currentPause.started_at || @currentPause.created_at
    return 0 if !raw

    startedAt = if typeof raw is 'number'
      ms = if raw < 1000000000000 then raw * 1000 else raw
      new Date(ms)
    else
      new Date(raw)

    return 0 if isNaN(startedAt.getTime())

    Math.floor((new Date().getTime() - startedAt.getTime()) / 1000)

  formatDuration: (seconds) ->
    seconds = Math.max(0, Math.floor(seconds || 0))
    h = Math.floor(seconds / 3600)
    m = Math.floor((seconds % 3600) / 60)
    s = seconds % 60
    pad = (n) -> (if n < 10 then "0#{n}" else "#{n}")
    if h > 0 then "#{h}:#{pad(m)}:#{pad(s)}" else "#{pad(m)}:#{pad(s)}"

  updateElapsed: ->
    return if !@visible || !@currentPause
    $overlay = @$overlay || $('.pause-blocker-overlay--fullscreen')
    return if !$overlay.length

    elapsed = @getElapsedSeconds()
    elapsedFormatted = @formatDuration(elapsed)
    $overlay.find('.js-elapsed-time').text(elapsedFormatted)

    # Check if time just exceeded
    timeLimit = @pauseType?.time_limit || @currentPause?.time_limit || 0
    wasExceeded = @timeExceeded
    @timeExceeded = timeLimit > 0 && elapsed > (timeLimit * 60)

    # Re-render if exceeded status changed
    if @timeExceeded && !wasExceeded
      @render()

  startElapsedTimer: ->
    return if @elapsedTimer
    @elapsedTimer = setInterval((=> @updateElapsed()), 1000)

  stopElapsedTimer: ->
    return if !@elapsedTimer
    clearInterval(@elapsedTimer)
    @elapsedTimer = null

  release: ->
    @stopElapsedTimer()
    if @statusTimer
      clearInterval(@statusTimer)
      @statusTimer = null
    @$overlay = null
    $('.pause-blocker-overlay--fullscreen').remove()
    $('body').removeClass('is-pause-blocked')
    super

# Initialize as a plugin
App.Config.set('pause_blocker', App.PauseBlocker, 'Plugins')
