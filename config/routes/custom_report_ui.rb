# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: relatório personalizado.

Zammad::Application.routes.draw do
  # A tela de relatório usa o bundle da Desktop View, mas mora fora de /desktop:
  # é uma guia independente, sem a navegação lateral, e a URL precisa refletir
  # isso. Serve o mesmo HTML; quem decide a base do roteador é o próprio app
  # (ver app/frontend/apps/desktop/router/index.ts).
  #
  # O curinga existe para o roteador do Vue poder navegar dentro de /report sem
  # o servidor devolver 404 num refresh.
  get '/report', to: 'desktop#index'
  get '/report/*path', to: 'desktop#index'
end
