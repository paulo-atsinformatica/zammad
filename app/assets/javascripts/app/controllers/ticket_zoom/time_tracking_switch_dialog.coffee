class App.TicketZoomTimeTrackingSwitchDialog extends App.ControllerModal
  buttonClose: true
  buttonCancel: true
  buttonSubmit: __('Switch and Start')
  head: __('Active Ticket Found')

  content: ->
    """
    <div class="modal-body">
      <p><%- @T('You already have an active time tracking on ticket') %> <strong>#{@existing_ticket_number}</strong>.</p>
      <p><%- @T('Do you want to pause that ticket and start tracking this one?') %></p>
    </div>
    """

  onSubmit: (e) ->
    e.preventDefault()
    @ajax(
      id:          'time_tracking_switch'
      type:        'POST'
      url:         "#{@apiPath}/tickets/#{@ticket_id}/time_tracking/switch"
      data:        JSON.stringify(from_ticket_id: @existing_ticket_id)
      processData: false
      contentType: 'application/json'
      success:     (data, status, xhr) =>
        @close()
        if @callback
          @callback()
        @notify(
          type:    'success'
          msg:     __('Time tracking switched')
          timeout: 2000
        )
      error: (xhr) =>
        @notify(
          type:    'error'
          msg:     xhr.responseJSON?.error || __('Failed to switch time tracking')
          timeout: 5000
        )
    )




