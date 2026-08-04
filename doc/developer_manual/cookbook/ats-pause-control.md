# Controle de Pausas e Tempo de Atendimento (ATS)

Este documento descreve a funcionalidade de controle de pausas e tempo de atendimento adicionada ao Zammad (fork ATS), incluindo o fluxo de login/logout do controle, estados do agente e relatório.

## Visao geral

- A topbar exibe o estado do agente (online/offline/pausa) e permite iniciar pausas.
- Antes de usar os controles, o agente precisa efetuar **Login** no controle de pausas.
- O **Logout** encerra o controle de pausas e oculta as opcoes ate um novo login.
- Login/Logout sao registrados e aparecem no relatorio de pausas.

## Fluxo do controle de pausas

1. O agente clica em **Login** na topbar.
2. As opcoes **Offline**, **Online** e pausas ficam disponiveis.
3. Ao iniciar uma pausa, o agente entra em estado de pausa e o tempo passa a ser contabilizado.
4. Ao sair da pausa, o agente retorna automaticamente para **Online**.
5. O agente pode encerrar o controle usando **Logout** (na ultima opcao do menu).

## Endpoints de API

- `POST /api/v1/user_pause_sessions/login`
- `POST /api/v1/user_pause_sessions/logout`
- `GET /api/v1/user_pause_sessions/current`
- `POST /api/v1/user_pauses/start`
- `POST /api/v1/user_pauses/end`
- `GET /api/v1/user_pauses/current`
- `GET /api/v1/reports/user_pauses`

## Relatorio de pausas

O relatorio em `#report/user_pauses` lista eventos de pausa e de login/logout.

Colunas:
- Agente
- Nome da Pausa/Login/Logout
- Data
- Hora
- Hora Fim
- Tempo Maximo Permitido
- Duracao Total
- Tempo excedido

Filtros:
- Data inicial/final
- Tipo de pausa (inclui Login/Logout)
- Agente (nome ou email)

## Modelos e dados

- `UserPause` registra as pausas.
- `UserPauseSession` registra os logins e logouts do controle.

Os eventos de login/logout aparecem no relatorio com `Nome da Pausa/Login/Logout` igual a "Login/Logout".
