# Modificações de Branding ATS - Customização do Zammad

Este documento descreve todas as alterações feitas neste repositório em relação ao Zammad original para implementar o branding ATS (vermelho escuro #480404).

## Visão Geral

Este fork do Zammad foi customizado para substituir as cores padrão (verde e azul) pela identidade visual ATS, utilizando principalmente o vermelho escuro `#480404` e o vermelho claro `#a40404`.

## Arquivos Modificados

### 1. `app/assets/stylesheets/zammad.scss`

**Arquivo principal de estilos** - Contém a maioria das alterações de branding.

#### Variáveis CSS - Cores Principais

**Modo Claro (`:root`):**
- `--button-primary-background`: Alterado de `hsl(203, 65%, 55%)` (azul) para `#480404` (vermelho escuro)
- `--button-primary-background-active`: Alterado de `hsl(203, 65%, 45%)` para `#8a0303` (vermelho mais escuro)
- `--text-link`: Alterado para `#480404` (vermelho escuro)
- `--text-nav`: Alterado para `#480404` (vermelho escuro)
- `--highlight`: Alterado de `hsl(205, 90%, 60%)` (azul) para `#480404` (vermelho escuro)
- `--background-active`: Alterado para `#480404` (vermelho escuro)
- `--menu-background-active`: Alterado para `hsl(0, 65%, 55%)` (vermelho claro)
- `--supergood-color`: Alterado para `#480404` (vermelho escuro)
- `--good-color`: Alterado para `#480404` (vermelho escuro)
- `--ghost-color`: Alterado de `hsl(0, 0%, 74%)` (cinza) para `hsl(0, 0%, 100%)` (branco)
- `--menu-text`: Alterado de `hsl(0, 0%, 74%)` (cinza) para `hsl(0, 0%, 100%)` (branco)
- `--nav-icon`: Alterado de `hsl(0, 0%, 50%)` (cinza) para `hsl(0, 0%, 100%)` (branco)
- `--menu-icon`: Alterado de `hsl(206, 5%, 42%)` para `hsl(0, 0%, 100%)` (branco)
- `--menu-icon-secondary`: Alterado de `hsl(0, 0%, 30%)` para `hsl(0, 0%, 100%)` (branco)

**Modo Escuro (`[data-theme='dark']`):**
- `--button-primary-background`: Alterado para `#a40404` (vermelho claro)
- `--button-primary-background-active`: Alterado para `#8a0303` (vermelho mais escuro)
- `--text-link`: Alterado para `white` (branco)
- `--text-nav`: Alterado para `white` (branco)

#### Navegação e Menu

- `.tasks-navigation`: Fundo alterado para `#480404 !important` (tema claro e escuro)
- `.user-menu`: Fundo alterado para `#480404 !important` (tema claro e escuro)
- `.tasks.tasks-navigation`: Fundo alterado para `#480404 !important` (tema claro e escuro)

#### Ícones

- `.user-menu-icon.icon-plus`: 
  - Cor padrão: `white !important`
  - Hover: `#480404 !important` (vermelho escuro)
  - Aplicado em ambos os temas

- `.user-menu-icon.icon-report` e `.user-menu-icon.icon-cog`:
  - Hover: `#480404 !important` (vermelho escuro)
  - Aplicado em ambos os temas

- `.icon-logo`:
  - Cor: `white !important` (tema claro e escuro)

#### Campo de Busca Global

- `.search input[type='search']`:
  - Fundo: `white !important` (tema claro e escuro)

- `.search .icon-magnifier`:
  - Fill: `#480404 !important` (vermelho escuro, tema claro e escuro)

#### Switch (Toggle)

- `.zammad-switch label`:
  - Fundo: `white !important` (sempre branco, tema claro e escuro)

- `.zammad-switch label::after` (bolinha):
  - Desativado: `#a40404 !important` (vermelho claro)
  - Ativado: `#38AE6A !important` (verde - mantido)

- `.zammad-switch input:checked + label`:
  - Fundo: `white !important` (sempre branco mesmo quando ativado)

#### Botões

- `.btn--primary`:
  - Usa `var(--button-primary-background)` que foi alterado para vermelho
  - Aplicado em todos os botões primários (ex: "Atualizar", "Adicionar lista de verificação vazia")

- `.btn--positive`, `.btn--create`, `.btn--success`:
  - Fundo: `#480404` (vermelho escuro)

### 2. `app/assets/javascripts/app/controllers/_dashboard/stats/ticket_waiting_time.coffee`

**Alteração na cor do gráfico stat-dial:**

- `handlingTimeColors['supergood']`: Alterado de `#38AE6A` (verde) para `#480404` (vermelho escuro)

O canvas que exibe o gráfico circular de tempo de espera agora usa vermelho escuro em vez de verde quando o estado é "supergood".

### 3. `public/assets/images/icons.svg`

**Alterações diretas em ícones SVG:**

- `icon-mood-supergood`: 
  - `fill="#38AE6A"` alterado para `fill="#480404"` (vermelho escuro)

- `icon-stopwatch` (dentro do círculo):
  - Adicionado `fill="#480404"` (vermelho escuro)

### 4. `app/frontend/apps/desktop/styles/tokens.css`

**Tokens de cores para a aplicação desktop:**

- `--color-green-400`: Alterado de `#ec241c` para `#480404` (vermelho escuro)
- `--color-green-500`: Alterado de `#ec241c` para `#480404` (vermelho escuro)
- `--color-green`: Alterado de `#ec241c` para `#480404` (vermelho escuro)

### 5. `app/frontend/apps/mobile/styles/tokens.css`

**Tokens de cores para a aplicação mobile:**

- `--color-green-400`: Alterado de `#ec241c` para `#480404` (vermelho escuro)
- `--color-green-500`: Alterado de `#ec241c` para `#480404` (vermelho escuro)
- `--color-green`: Alterado de `#ec241c` para `#480404` (vermelho escuro)

### 6. `app/assets/stylesheets/knowledge_base.scss`

**Estilos da base de conhecimento:**

- Background alterado de `hsl(0, 65%, 55%)` para `#480404` (vermelho escuro)

### 7. `app/views/init/spinner-loading.html.erb`

**Tela de carregamento:**

- `html` tag: `background-color` alterado de `var(--background-primary)` para `#480404` (vermelho escuro)

## Resumo das Cores Utilizadas

### Cores Principais ATS

- **Vermelho Escuro**: `#480404` - Cor principal do branding ATS
- **Vermelho Claro**: `#a40404` - Usado em botões no modo escuro e estados hover
- **Vermelho Mais Escuro**: `#8a0303` - Usado em estados ativos de botões
- **Branco**: `white` ou `hsl(0, 0%, 100%)` - Usado em ícones, textos e fundos de switch

### Substituições de Cores

| Cor Original | Nova Cor ATS | Uso |
|------------|-------------|-----|
| Verde (`#38AE6A`, `hsl(0, 65%, 55%)`) | Vermelho Escuro (`#480404`) | Ícones, links, destaques |
| Azul (`hsl(203, 65%, 55%)`) | Vermelho Escuro (`#480404`) | Botões primários (tema claro) |
| Azul Claro (`hsl(205, 90%, 60%)`) | Vermelho Escuro (`#480404`) | Destaques, seleções |
| Cinza (`hsl(0, 0%, 74%)`, `hsl(0, 0%, 50%)`) | Branco (`white`) | Ícones, textos de navegação |

## Compatibilidade com Temas

Todas as alterações foram aplicadas considerando:
- **Tema Claro**: Cores principais em vermelho escuro (`#480404`)
- **Tema Escuro**: Cores ajustadas para melhor contraste (vermelho claro `#a40404` em botões, branco em textos)

## Notas Técnicas

1. **Uso de `!important`**: Algumas regras utilizam `!important` para garantir que as cores customizadas sobrescrevam estilos padrão do Zammad.

2. **Variáveis CSS**: A maioria das alterações foi feita através de variáveis CSS (`--*`) para facilitar manutenção futura.

3. **Compatibilidade**: As alterações mantêm a estrutura e funcionalidade original do Zammad, alterando apenas cores e estilos visuais.

4. **Build**: Após as alterações, é necessário fazer rebuild dos assets:
   ```bash
   cd source
   docker build --build-arg COMMIT_SHA=$(git rev-parse HEAD) -t ghcr.io/paulo-atsinformatica/zammad:2.0.2 -t ghcr.io/paulo-atsinformatica/zammad:latest .
   ```

## Branch

Todas as alterações estão na branch: `custom-branding-ats`

## Data das Alterações

Alterações realizadas em: Dezembro 2024

## Manutenção Futura

Para atualizar o Zammad original mantendo as customizações:

1. Fazer merge da branch `main` do Zammad original
2. Resolver conflitos mantendo as alterações de branding
3. Testar em ambos os temas (claro e escuro)
4. Rebuild da imagem Docker

## Sistema de Controle de Tempo e Pausas

Este sistema foi implementado para controlar o tempo de atendimento por ticket e gerenciar pausas globais dos responsáveis.

### Novas Tabelas de Banco de Dados

1. **`pause_types`**: Tipos de pausa configuráveis (nome, tempo limite, cor, ativo)
2. **`user_pauses`**: Registro de pausas dos usuários (usuário, tipo de pausa, início, fim, motivo de atraso)
3. **`ticket_time_trackings`**: Controle de tempo por ticket (ticket, usuário, início, pausas, retomadas, fim, total de segundos)

### Novos Campos em `users`

- `enable_pause_control`: Boolean - Habilita controle de pausas
- `enable_ticket_time_tracking`: Boolean - Habilita controle de tempo por ticket
- `current_state`: String - Estado atual ('offline', 'online', 'pause')
- `current_pause_id`: Foreign key - Referência à pausa ativa
- `current_active_ticket_id`: Foreign key - Referência ao ticket com atendimento ativo

### Novos Modelos Ruby

1. **`PauseType`**: Model para tipos de pausa
2. **`UserPause`**: Model para pausas de usuários
3. **`TicketTimeTracking`**: Model para controle de tempo de tickets

### Novos Controllers e Services

1. **`PauseTypesController`**: CRUD para tipos de pausa (apenas administradores)
2. **`UserPausesController`**: Gerenciar pausas do usuário atual
3. **`TicketTimeTrackingsController`**: Gerenciar tracking de tempo de tickets
4. **`UserStatesController`**: Gerenciar estado do usuário (offline/online)
5. **`UserPausesReportsController`**: Relatórios de pausas
6. **`UserPauseService`**: Service para lógica de pausas
7. **`TicketTimeTrackingService`**: Service para lógica de tracking

### Novos Componentes Frontend

1. **`App.TicketZoomTimeTracking`**: Componente de controle de tempo no ticket zoom
2. **`App.NavigationUserState`**: Menu de estado no menu lateral
3. **`App.ApplicationPauseBlocker`**: Sistema de bloqueio de interface quando em pausa
4. **`App.UserPauseDelayReasonDialog`**: Modal de motivo de atraso
5. **`ManagePauseTypes`**: Tela de cadastro de tipos de pausa
6. **`ReportUserPauses`**: Relatórios de pausas

### Novas Rotas

- `/api/v1/pause_types` - CRUD de tipos de pausa
- `/api/v1/user_pauses/*` - Gerenciar pausas
- `/api/v1/user_states/*` - Gerenciar estados
- `/api/v1/tickets/:ticket_id/time_tracking/*` - Gerenciar tracking de tempo
- `/api/v1/user_pauses_reports` - Relatórios

### Funcionalidades

1. **Controle de Tempo por Ticket**: Botões para iniciar/pausar/retomar atendimento, com indicador de tempo em tempo real
2. **Menu de Estado**: Menu no sidebar para definir estado (Offline/Online) e iniciar pausas
3. **Bloqueio de Interface**: Overlay que bloqueia todas as ações quando o usuário está em pausa
4. **Modal de Motivo de Atraso**: Modal obrigatório quando o tempo limite da pausa é excedido
5. **Cadastro de Tipos de Pausa**: Tela de administração para gerenciar tipos de pausa
6. **Relatórios**: Relatórios de pausas por usuário e por tipo de pausa

### Validações e Callbacks

- Apenas um ticket ativo por usuário
- Bloqueio de ações quando usuário está em pausa
- Finalização automática de tracking quando ticket é fechado ou desatribuído
- Validação de tempo limite de pausas

### Migrações

- `20251224120000_create_pause_types.rb`
- `20251224120001_create_user_pauses.rb`
- `20251224120002_create_ticket_time_trackings.rb`
- `20251224120003_add_time_tracking_fields_to_users.rb`

### Testes

- `spec/models/pause_type_spec.rb`
- `spec/models/user_pause_spec.rb`
- `spec/models/ticket_time_tracking_spec.rb`
- Factories criadas em `spec/factories/`

## Referências

- Repositório original: https://github.com/zammad/zammad
- Documentação Zammad: https://docs.zammad.org/
- Branch customizada: `custom-branding-ats`

