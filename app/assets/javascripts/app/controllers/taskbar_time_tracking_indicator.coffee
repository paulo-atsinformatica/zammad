# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Marca, na lista de abas da lateral, qual ticket está com o tempo de
# atendimento em contagem. Precisa ser um plugin global (e não parte do
# App.TicketZoomTimeTracking) porque o indicador tem de aparecer enquanto o
# agente está em outra aba, onde o player daquele ticket não está montado.
class App.TaskbarTimeTrackingIndicator extends App.Controller
  # Classes aplicadas na âncora da aba (app/views/widget/task_item.jst.eco)
  activeClass: 'is-time-tracking'
  pausedClass: 'is-time-tracking-paused'

  constructor: ->
    super

    @ticketId = null
    @isPaused = false

    @readInitialState()

    # Estado vem dos eventos de WebSocket do próprio usuário.
    @controllerBind('TicketTimeTracking:stateChange', @onStateChange)
    @controllerBind('TicketTimeTracking:destroyed', @onDestroyed)

    # A taskbar recria o DOM das abas nesses eventos, o que apaga as classes.
    @controllerBind('taskInit taskUpdate', @refresh)

  # O usuário atual carrega current_active_ticket_id (customização ATS), então
  # o indicador já aparece certo num F5 sem esperar evento de WebSocket.
  readInitialState: ->
    currentUser = App.User.current()
    return if !currentUser

    @ticketId = currentUser.current_active_ticket_id || null
    @isPaused = false
    @refresh()

  onStateChange: (data) =>
    return if !data
    return if data.user_id != App.User.current()?.id

    switch data.current_state
      when 'running'
        @ticketId = data.ticket_id
        @isPaused = false
      when 'paused'
        @ticketId = data.ticket_id
        @isPaused = true
      else # 'ended' / 'inactive'
        @ticketId = null if @ticketId == data.ticket_id
        @isPaused = false

    @refresh()

  onDestroyed: (data) =>
    return if !data
    return if data.user_id != App.User.current()?.id
    return if @ticketId != data.ticket_id

    @ticketId = null
    @isPaused = false
    @refresh()

  refresh: =>
    @clear()
    return if !@ticketId

    tab = $(".nav-tab.task[data-key='Ticket-#{@ticketId}']")
    return if !tab.length

    tab.addClass(@activeClass)
    tab.toggleClass(@pausedClass, @isPaused)

  clear: ->
    $(".nav-tab.task.#{@activeClass}").removeClass("#{@activeClass} #{@pausedClass}")

  release: ->
    @clear()
    super

# Initialize as a plugin
App.Config.set('taskbar_time_tracking_indicator', App.TaskbarTimeTrackingIndicator, 'Plugins')
