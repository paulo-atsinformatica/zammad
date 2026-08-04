class App.UserPauseDelayReasonDialog extends App.ControllerModal
  buttonClose: false
  buttonCancel: true
  buttonSubmit: __('Sair da Pausa')
  head: __('Tempo de Pausa Excedido')

  content: ->
    """
    <div class="modal-body">
      <p><%- @T('O tempo limite da pausa foi excedido. Por favor, informe o motivo do atraso.') %></p>
      <div class="form-group">
        <label for="delay_reason"><%- @T('Motivo do Atraso') %> <span class="required">*</span></label>
        <textarea id="delay_reason" class="form-control" rows="4" required></textarea>
      </div>
    </div>
    """

  onSubmit: (e) ->
    e.preventDefault()
    delayReason = @el.find('#delay_reason').val().trim()
    if !delayReason
      @notify(
        type:    'error'
        msg:     __('Delay reason is required')
        timeout: 3000
      )
      return

    if @callback
      @callback(delayReason)
    @close()




