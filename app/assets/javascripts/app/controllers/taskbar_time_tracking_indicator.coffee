# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Mostra, na aba da lateral, o tempo de atendimento correndo do ticket em
# contagem. Precisa ser um plugin global (e não parte do
# App.TicketZoomTimeTracking) porque o cronômetro tem de continuar visível
# enquanto o agente trabalha em outra aba, onde o player daquele ticket não está
# montado.
#
# O nó do cronômetro é injetado por JS em vez de alterar
# app/views/widget/task_item.jst.eco, para não carregar um arquivo do upstream
# na diferença do fork.
class App.TaskbarTimeTrackingIndicator extends App.Controller
  activeClass: 'is-time-tracking'
  pausedClass: 'is-time-tracking-paused'
  timerClass:  'nav-tab-timeTracking'

  constructor: ->
    super

    @ticketId = null
    @isPaused = false
    @baseSeconds = 0
    @runningSince = null
    @timer = null

    @readInitialState()

    @controllerBind('TicketTimeTracking:stateChange', @onStateChange)
    @controllerBind('TicketTimeTracking:destroyed', @onDestroyed)

    # A taskbar recria o DOM das abas nesses eventos, o que remove o cronômetro.
    @controllerBind('taskInit taskUpdate', @refresh)

  # Mesma base do player em App.TicketZoomTimeTracking#baseSeconds: o acumulado
  # deste usuário NO TICKET, e não só do registro atual.
  #
  # Cada passagem pelo ticket cria um registro próprio. Lendo total_seconds, um
  # agente que devolvia o ticket e o recebia de volta via a aba zerar em 00:00:00
  # enquanto o player embaixo mostrava o tempo certo — os dois liam campos
  # diferentes do mesmo payload.
  baseFrom: (data, fallback = 0) ->
    return fallback if !data
    return data.ticket_total_seconds if data.ticket_total_seconds?
    return data.total_seconds if data.total_seconds?
    fallback

  # Num F5 o usuário já traz current_active_ticket_id (customização ATS), mas
  # não o tempo acumulado — daí a consulta ao endpoint para o cronômetro não
  # começar do zero.
  readInitialState: ->
    currentUser = App.User.current()
    return if !currentUser

    ticketId = currentUser.current_active_ticket_id
    return if !ticketId

    @ajax(
      id:          'taskbar_tt_initial'
      type:        'GET'
      url:         "#{@apiPath}/tickets/#{ticketId}/time_tracking/current"
      processData: true
      success: (data) =>
        return if !data or !data.id

        @applyState(
          ticket_id:            ticketId
          total_seconds:        data.total_seconds
          ticket_total_seconds: data.ticket_total_seconds
          resumed_at:           data.resumed_at
          started_at:           data.started_at
          current_state:        if data.is_active && !data.paused_at then 'running' else 'paused'
        )
    )

  onStateChange: (data) =>
    return if !data
    return if data.user_id != App.User.current()?.id

    @applyState(data)

  onDestroyed: (data) =>
    return if !data
    return if data.user_id != App.User.current()?.id
    return if @ticketId != data.ticket_id

    @reset()

  applyState: (data) =>
    switch data.current_state
      when 'running'
        @ticketId     = data.ticket_id
        @isPaused     = false
        @baseSeconds  = @baseFrom(data)
        @runningSince = new Date(data.resumed_at || data.started_at)
        @startTimer()
      when 'paused'
        @ticketId     = data.ticket_id
        @isPaused     = true
        @baseSeconds  = @baseFrom(data)
        @runningSince = null
        @stopTimer()
        @refresh()
      else # 'ended' / 'inactive'
        return if @ticketId && @ticketId != data.ticket_id
        @reset()

  reset: =>
    @ticketId     = null
    @isPaused     = false
    @baseSeconds  = 0
    @runningSince = null
    @stopTimer()
    @clear()

  startTimer: ->
    @stopTimer()
    @refresh()
    @timer = setInterval(@refresh, 1000)

  stopTimer: ->
    return if !@timer
    clearInterval(@timer)
    @timer = null

  elapsedSeconds: ->
    return @baseSeconds if @isPaused or !@runningSince

    @baseSeconds + Math.floor((new Date() - @runningSince) / 1000)

  formatted: ->
    total   = Math.max(@elapsedSeconds(), 0)
    hours   = Math.floor(total / 3600)
    minutes = Math.floor((total % 3600) / 60)
    seconds = total % 60
    pad     = (value) -> if value < 10 then "0#{value}" else "#{value}"

    "#{pad(hours)}:#{pad(minutes)}:#{pad(seconds)}"

  refresh: =>
    @clear()
    return if !@ticketId

    tab = $(".nav-tab.task[data-key='Ticket-#{@ticketId}']")
    return if !tab.length

    tab.addClass(@activeClass)
    tab.toggleClass(@pausedClass, @isPaused)

    # Antes do botão de fechar, para não empurrar o X para fora da aba.
    $('<div/>')
      .addClass(@timerClass)
      .text(@formatted())
      .insertBefore(tab.find('.nav-tab-close'))

  clear: ->
    $(".nav-tab.task.#{@activeClass}").removeClass("#{@activeClass} #{@pausedClass}")
    $(".#{@timerClass}").remove()

  release: ->
    @stopTimer()
    @clear()
    super

# Initialize as a plugin
App.Config.set('taskbar_time_tracking_indicator', App.TaskbarTimeTrackingIndicator, 'Plugins')
