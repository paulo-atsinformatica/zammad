class App.TicketZoomTitle extends App.ControllerObserver
  model: 'Ticket'
  template: 'ticket_zoom/title'
  observe:
    title: true
  globalRerender: false

  events:
    'blur .js-objectTitle': 'update'

  renderPost: (object) =>
    # Customização ATS: o título era sempre editável, independente de permissão.
    # Sem isto, um cliente com acesso somente leitura (ou um agente com apenas
    # 'read' no grupo) consegue digitar no título e só toma erro ao salvar.
    return if !object.editable()

    @$('.js-objectTitle').ce({
      mode:      'textonly'
      multiline: false
      maxlength: 250
    })

  update: (e) =>
    ticket = App.Ticket.find(@object_id)
    return if !ticket.editable()

    title = $(e.target).ceg() || ''

    # update title
    return if title is @lastAttributes.title

    ticket.title = title

    # reset article - should not be resubmitted on next ticket update
    ticket.article = undefined

    ticket.save(
      url: "#{App.Config.get('api_path')}/tickets/#{@object_id}/update_title"
    )

    App.TaskManager.mute(@taskKey)

    # update taskbar with new meta data
    App.TaskManager.touch(@taskKey)

    App.Event.trigger('overview:fetch')
