# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# Pause Blocker - Desativado: controle de pausa é feito apenas pela topbar (UserStatusBar).
# Este plugin não exibe mais o overlay fullscreen; mantido apenas para não quebrar referências.
class App.PauseBlocker extends App.Controller

  constructor: ->
    super
    @currentUser = App.User.current()
    return if !@currentUser?.permission('user.pause_control')
    # Não fazer nada: não abrir overlay, não escutar eventos, não fazer polling.
    return

# Initialize as a plugin
App.Config.set('pause_blocker', App.PauseBlocker, 'Plugins')
