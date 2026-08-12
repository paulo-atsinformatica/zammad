# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: copiar o número do ticket em qualquer lista de tickets
# (views/generic/ticket_list.jst.eco), inclusive dentro do balão de
# "Tickets abertos/fechados" que aparece ao passar o mouse sobre o cliente/
# organização no ticket zoom.
#
# Esse balão é um popover do Bootstrap injetado direto no <body>
# (App.PopoverProviderAjax#replaceOnShow), sem controller Spine dono do HTML.
# Por isso o clique não pode ser ligado por um @events de controller, como o
# resto do app faz — precisa de delegação global no document, que funciona
# tanto ali quanto nos outros lugares que reaproveitam o mesmo template
# (Cliente/Organização, Tickets relacionados, tickets vinculados da base de
# conhecimento).
$(document).on 'click', '.js-ticketListNumberCopy', (event) ->
  event.preventDefault()
  event.stopPropagation()

  icon   = $(@)
  number = icon.data('number')
  return if !number

  clipboard.writeText(String(number))

  # Troca de ícone em vez de chamar um helper de renderização: fora de um
  # controller não há @Icon disponível, e os dois estados já vêm prontos do
  # template, então aqui é só alternar a classe hide.
  icon.find('.js-ticketListNumberCopy-idle').addClass('hide')
  icon.find('.js-ticketListNumberCopy-done').removeClass('hide')

  App.Delay.set(
    ->
      icon.find('.js-ticketListNumberCopy-done').addClass('hide')
      icon.find('.js-ticketListNumberCopy-idle').removeClass('hide')
    1500
    "ticketListNumberCopy-#{_.uniqueId()}"
  )
