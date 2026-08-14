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

Para sincronizar com o Zammad original sem perder as customizações ATS (branding e sistema de pausas), use o guia completo:

- **[.dev/sync-upstream-guide.md](.dev/sync-upstream-guide.md)** – Passo a passo, lista de arquivos a preservar em conflitos e script opcional.

Resumo: fazer merge da branch `develop` (ou `stable-*`) do upstream; em conflitos nos arquivos de branding e do sistema de pausas, manter as alterações ATS; testar em ambos os temas (claro e escuro); rebuild da imagem Docker.

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

### Painel público de indicadores de pausa – SSE (tempo real)

O painel em `/monitor/pause_indicators` usa **Server-Sent Events (SSE)** para atualizar em tempo real quando alguém muda estado/pausa. Para isso funcionar na produção:

1. **Redis** deve estar acessível pelo Zammad (o endpoint `/api/v1/public_pause_indicators/stream` retorna 503 se Redis não estiver disponível e o frontend cai no polling de 5s).
2. **Nginx (ou proxy reverso)** deve tratar o endpoint de stream sem buffering e com timeout longo:
   - `proxy_buffering off;` e `proxy_cache off;`
   - `proxy_read_timeout` e `proxy_send_timeout` longos (ex.: 86400s)
   - `chunked_transfer_encoding off;` (recomendado para SSE)

Os exemplos em `contrib/nginx/zammad.conf` e `contrib/nginx/zammad_ssl.conf` incluem um bloco `location /api/v1/public_pause_indicators/stream` com essa configuração. Se usar outro proxy (Coolify, Traefik, etc.), garanta o equivalente para que a conexão SSE permaneça aberta e não seja bufferizada.

Se nos logs do nginx **não** aparecer nenhuma requisição a `/api/v1/public_pause_indicators/stream` e só aparecer `GET /api/v1/public_pause_indicators?...` a cada ~5s, o SSE não está em uso e o painel está em modo polling.

### Balanceamento de carga (Nginx) e Redis

Para o **controle de pausas** funcionar corretamente com **vários nós** atrás de um balanceador (Nginx ou outro):

1. **Redis obrigatório**
   - Defina `REDIS_URL` (ou `REDIS_SENTINELS` para cluster) em todos os nós da aplicação.
   - O Zammad usa Redis para:
     - **WebSocket session store**: sessões de conexão longa e filas de mensagens; com Redis, todos os nós enxergam as mesmas sessões e o evento `pause_indicators:changed` chega a todos os clientes.
     - **Pub/Sub do painel público**: `PauseIndicatorsBroadcast` publica no canal `zammad:pause_indicators_changed`; cada nó que tem conexões SSE abertas inscreve-se nesse canal e repassa o evento aos clientes.
   - Se Redis não estiver configurado, o store de WebSocket usa arquivo (por nó) e o painel público não usa SSE (só polling).

2. **Sessão HTTP (Rails)**
   - O Zammad usa **Active Record** como session store (banco de dados), não cookie em memória. Assim, qualquer nó pode atender qualquer requisição HTTP; não é necessário sticky session para a API REST.

3. **WebSocket (`/ws`)**
   - A conexão WebSocket é longa e fica em um único nó. Para o mesmo cliente sempre ser atendido pelo mesmo backend, use **sticky session** no Nginx para o `location /ws`, por exemplo `ip_hash` no `upstream` (veja exemplo abaixo).

4. **SSE (`/api/v1/public_pause_indicators/stream`)**
   - Cada conexão SSE fica em um nó até fechar. Não é necessário sticky para o stream: quando alguém altera pausa, o servidor publica no Redis e **todos** os nós que têm clientes inscritos recebem e enviam `data: refresh` aos seus clientes.

5. **Exemplo de upstream com vários backends (Nginx)**

```nginx
# Vários nós Rails; ip_hash para que /ws caia sempre no mesmo backend por cliente
upstream zammad-railsserver {
  ip_hash;
  server 10.0.1.1:3000;
  server 10.0.1.2:3000;
  server 10.0.1.3:3000;
}

upstream zammad-websocket {
  ip_hash;
  server 10.0.1.1:6042;
  server 10.0.1.2:6042;
  server 10.0.1.3:6042;
}
```

Garanta que todos os nós usem o mesmo `REDIS_URL` (e o mesmo PostgreSQL). Os exemplos em `contrib/nginx/zammad.conf` e `contrib/nginx/zammad_ssl.conf` podem ser adaptados com esse `upstream` quando houver mais de um backend.

## Init em loop / "undefined method 'each' for String" (Docker)

**Contexto:** Após corrigir as variáveis de ambiente do Postgres (POSTGRESQL_* no compose), o `zammad-init` pode passar a chegar na etapa "Synchronizing locales and translations..." e falhar com `undefined method 'each' for an instance of String`, entrando em loop (restart on-failure).

**Causa do erro:** O código chama `Locale.sync`, que faz `YAML.load_file('config/locales.yml')`. O Psych (YAML do Ruby) retorna uma **String** quando o documento YAML tem como raiz um escalar (ex.: arquivo contendo só `---` e uma linha de texto, ou conteúdo que o parser interpreta como uma única string). Nesse caso, `data.each` quebra porque String não tem `.each` em Ruby 3.

**Quando o YAML pode retornar String:**
- **Volume ou mount** sobrescrevendo `config/` ou `/opt/zammad`: se no Coolify (ou no host) um volume montar em cima de `config/` ou do app, o arquivo `config/locales.yml` dentro do container pode ser outro (ex.: vazio, ou um arquivo de config que é um único valor).
- **Build da imagem:** se o contexto de build (ou um `.dockerignore` não documentado) não incluir `config/locales.yml` corretamente, o arquivo na imagem pode estar vazio ou ser outro.
- **Encoding / BOM:** em casos raros, BOM ou encoding do arquivo pode fazer o parser interpretar o documento como um único escalar.

**Por que apareceu “após as alterações recentes”:** Antes, o init falhava na conexão com o Postgres (variáveis POSTGRES_* vs POSTGRESQL_*). Depois de corrigir isso, o init passou a chegar na etapa de sync; aí o bug do YAML (ou do conteúdo do arquivo no ambiente) passou a se manifestar.

**O que foi feito no código:** Em `app/models/locale.rb`, `Locale.sync` foi tornado defensivo: se o YAML retornar String ou tipo inesperado, o método retorna `false` sem chamar `.each`, e grava no log um aviso com os primeiros 200 caracteres do valor (para diagnóstico). Assim o init não entra mais em loop por esse motivo.

**Como diagnosticar no próximo deploy:** Nos logs do container `zammad-init`, procure por:
`[Locale.sync] config/locales.yml retornou String (primeiros 200 chars): ...`
Isso mostra o que o arquivo realmente contém no ambiente. Se aparecer, confira no Coolify se há volume montado em `/opt/zammad` ou `config/` e se o `config/locales.yml` na imagem está correto (ex.: `docker run --rm ghcr.io/.../zammad:latest cat /opt/zammad/config/locales.yml | head -20`).

**Descobrindo a causa raiz (arquivo truncado no container):** Antes das alterações de i18n (chamado/tíquete → ticket) os idiomas funcionavam; depois o arquivo passou a ser lido como String "---" (truncado). Possíveis causas:
- **Cache do Docker build:** a camada `COPY . .` pode estar em cache de um build antigo em que o contexto tinha o arquivo ausente ou truncado. **Solução:** fazer build com `--no-cache` (ou `docker build --no-cache ...`) para forçar nova cópia do contexto; assim o `config/locales.yml` do repositório atual entra na imagem.
- **Verificação no build:** no `Dockerfile` foi adicionado um `RUN` que falha se `config/locales.yml` tiver menos de 500 bytes. Se o build passar, a imagem tem o arquivo completo; se falhar, o contexto ou o cache está com o arquivo errado (usar `--no-cache` e rebuild).
- **Diagnóstico no container (Coolify):** dentro do container em execução, rodar `wc -c /opt/zammad/config/locales.yml` e `head -5 /opt/zammad/config/locales.yml`. Se o tamanho for &lt; 500 bytes ou o conteúdo só "---", a imagem usada pelo Coolify está com o arquivo truncado (rebuild sem cache ou conferir qual imagem/digest o Coolify está puxando).

## Alterações de 28/07/2026 (pós-sync 7.2.x)

Feitas na branch `sync-upstream-20260727`, depois do merge com `upstream/develop`.
**Todas precisam ser reconferidas em syncs futuros** — as que tocam arquivo do
upstream são as que correm risco de serem perdidas num merge.

### Armadilhas herdadas do sync 7.2.x (ler antes de sincronizar de novo)

| O que aconteceu | Por que importa |
|---|---|
| Upstream removeu `Service::BaseWithCurrentUser` (commit `1e20dc5e1e`) e moveu `current_user` para `Service::Base`. `TicketTimeTrackingService` e `UserPauseService` herdavam da classe apagada. | **Derrubava o boot inteiro em produção** (`NameError` no eager_load). Invisível para rspec/rubocop/lint, porque nenhum deles faz eager_load. Corrigido em `6e77067b36`. **Sempre rodar `rails zeitwerk:check` depois de um sync.** |
| Upstream trocou a query GraphQL `TicketSignature` por um mecanismo de FormUpdater (commit `6822609aca`). O merge adotou o novo, mas deixou os arquivos antigos órfãos. | Sobraram `app/frontend/shared/composables/useTicketSignature.ts` (com bug inatingível), `app/frontend/shared/graphql/queries/ticketSignature.*`, `app/graphql/gql/queries/ticket/signature.rb`, `app/graphql/gql/types/signature_type.rb`. **Recomendado remover.** |
| `app/frontend/apps/desktop/entities/ticket/graphql/queries/customerTicketsByFilter.{api,mocks}.ts` | WIP abandonado: sem `.graphql` fonte, sem resolver no backend, não importado por ninguém. Só quebra o `pnpm lint:ts`. **Recomendado remover.** |
| `app/frontend/shared/graphql/types.ts` não foi regenerado no merge | 71 erros de tipo no `vue-tsc`. **Rodar `pnpm generate-graphql-api` depois de todo sync.** |
| 385 arquivos sob `public/assets/` estavam apagados do disco mas ainda versionados | Quebrava o boot (`icons.svg` ausente → 500 na tela inicial). Restaurados com `git checkout -- public/assets/`. Conferir com `git status --short \| grep '^ D'`. |

### Tempo de atendimento (player do ticket)

- **`app/assets/javascripts/app/controllers/ticket_zoom/time_tracking.coffee`** —
  adicionado `failResponseNoTrigger: true` nas chamadas de `start` e `resume`.
  O controller responde **409** quando já existe contagem em outro ticket, e o
  handler global de ajax (`app/assets/javascripts/app/lib/app_post/ajax.coffee`)
  só suprime o modal de erro técnico para 401/403/404/422/502 — sem esse flag,
  o modal "StatusCode: 409" aparecia por cima do diálogo de troca de ticket.
  **Se o upstream mexer nesse arquivo, reaplicar.**
- **`app/models/ticket_time_tracking.rb`** — em `notify_clients_data_attributes`
  e no broadcast de ticket, `total_seconds` passou a ser o **acumulado
  persistido** (igual à coluna e às respostas REST, que serializam atributos
  crus), e o total já calculado saiu em `total_time_seconds`. Antes o WebSocket
  mandava o total calculado sob a chave `total_seconds`, e como o frontend soma
  o tempo corrente por conta própria, o cronômetro contava o trecho em execução
  **duas vezes**. Coberto por specs em `spec/models/ticket_time_tracking_spec.rb`.
- **`app/assets/javascripts/app/views/ticket_zoom.jst.eco`** — o player saiu de
  `.ticketZoom-controls` (que rola junto com os artigos e desaparecia de vista)
  para a `.attributeBar` fixa. Fica como **irmão** de `.js-attributeBar`, nunca
  como filho: `App.TicketZoomAttributeBar#render` faz `@html` e substitui aquele
  nó inteiro em mudanças de macro, rascunho, grupo e idioma — dentro dele, o DOM
  do player seria destruído e o cronômetro congelaria em silêncio.
- **`app/assets/stylesheets/zammad.scss`** — `.attributeBar` virou flex,
  `.attributeBar-inner` ganhou `flex: 1`, e foi criado
  `.attributeBar-timeTracking`. Também as regras de `.nav-tab.is-time-tracking`
  (indicador na aba) e o keyframe `tt-tab-pulse`.
- **`app/assets/javascripts/app/controllers/taskbar_time_tracking_indicator.coffee`**
  (novo, ATS puro) — plugin global que marca a aba lateral do ticket em
  contagem. Tem de ser global porque o player só existe no ticket aberto.
  Reaplica a classe em `taskInit`/`taskUpdate`, já que a taskbar recria o DOM
  das abas.

### Acesso somente leitura para clientes

Objetivo: cliente entra no perfil dele e **apenas visualiza** — não muda
atributos, não renomeia, não adiciona artigo. Configurável por grupo.

- **`db/seeds/settings.rb`** e **`db/migrate/20260728000000_add_customer_ticket_update_settings.rb`**
  — settings `customer_ticket_update` (booleano) e
  `customer_ticket_update_group_ids` (seleção de grupos, vazio = todos),
  espelhando `customer_ticket_create`. Default `true`, para não travar ninguém
  ao atualizar.
- **`app/policies/ticket_policy.rb`** — `change_access?` consulta
  `customer_update_allowed?`. **Este é o bloqueio de verdade**, e cobre também
  renomear (`update_title` chama `authorize!(:update?)`) e criar artigo
  (`follow_up?` cai em `update?`). Bloqueio só no frontend seria burlado por
  API. Ausência do setting mantém o comportamento antigo (não bloqueia).
- **`app/assets/javascripts/app/models/ticket.coffee`** — `editableByCustomer`
  passou a consultar `updatableByCustomer()`. Como `editable()` é o gate central
  do zoom, isso cascateia para caixa de resposta, atributos da lateral e
  attribute bar de uma vez.
- **`app/assets/javascripts/app/controllers/ticket_zoom/title.coffee`** — passou
  a checar `editable()` no `renderPost` e no `update`. **Antes não checava
  nada**, então até um agente com acesso só de leitura no grupo conseguia
  digitar no título e só tomava erro ao salvar.
- Specs em `spec/policies/ticket_policy_spec.rb` (bloco "read-only access for
  customers"), incluindo o caso de que bloquear alteração **não** pode esconder
  o ticket do cliente.

### Mensagens de bloqueio em português

- **`lib/translation_overrides_pt_br.rb`** — traduções das mensagens de
  permissão. Este é o caminho preferido: as mensagens do backend passam por
  `App.i18n.translateContent` no frontend
  (`app/assets/javascripts/app/controllers/_plugin/notify.coffee`), então dá
  para traduzir **sem alterar arquivo do upstream** — inclusive as que o Zammad
  não marca com `__()` e que por isso nunca chegariam ao catálogo. Os msgid
  incluem o formato literal `"Not authorized (motivo)!"` que
  `PunditPolicy#not_authorized` monta.
  Este arquivo é ATS puro e roda pelo `bin/docker-entrypoint`, então **não
  conflita em sync**. Preferir sempre este caminho a editar `.po` (que o
  upstream/Weblate sobrescreve).
- **`app/models/concerns/can_perform_changes.rb`** (arquivo do upstream) — o
  `raise` de string crua virou `Exceptions::UnprocessableContent` com mensagem
  traduzível. Antes, rodar uma macro cujas ações o usuário não pode aplicar
  gerava **HTTP 500** e, por consequência, modal de erro técnico em inglês
  (500 não está na whitelist do handler global de ajax). Agora é 422, que vira
  um toast legível. **Reaplicar se o upstream mexer nesse arquivo.**

- **`app/models/concerns/checks_core_workflow.rb`** (arquivo do upstream) — as
  duas mensagens de rejeição do Core Workflow. Estas **não** dão para resolver
  pelo arquivo de override: o nome do campo é interpolado antes de a mensagem
  chegar ao frontend, então não sobra msgid para o `App.i18n` casar. Por isso
  são traduzidas **no servidor**, via `Translation.translate(locale, ...)` com
  a cadeia de fallback usual (`user.locale || locale_default || 'en-us'`), no
  mesmo padrão de `cti/driver/base.rb` e `checks_human_changes.rb`.
  Também passaram a mostrar o **rótulo do campo** em vez do nome cru da coluna
  (era `"Invalid value '3' for field 'state_id'!"`). A busca do rótulo é
  cosmética e cai no nome da coluna se falhar — transformar um erro de
  validação legível em 500 seria pior que um rótulo feio.
  **Reaplicar se o upstream mexer nesse arquivo.** Expectativas ajustadas em
  `spec/models/concerns/checks_core_workflow_examples.rb` e
  `spec/graphql/gql/mutations/ticket/create_spec.rb`.

Regra geral para traduzir mensagem de backend: se a string chega **inteira** ao
frontend, basta adicionar o msgid em `lib/translation_overrides_pt_br.rb` (ATS
puro, sem conflito em sync). Se a string tem **valor interpolado**, tem de ser
traduzida no servidor com `Translation.translate`.

### Relatório personalizado (feature ATS, fase 1)

Duas telas, de propósito em interfaces diferentes:

- **Configurar** — Gerenciar → Relatórios Personalizados, no SPA legado
  (`admin.custom_report`). Define objeto, visibilidade, colunas exibidas e quais
  filtros ficam disponíveis para quem visualiza.
- **Visualizar** — `/desktop/custom-reports`, na **Desktop View (Vue)**. Grid
  paginado, botão de filtros, exportação em fila e download.

A tela de visualização usa o **bundle** da Desktop View, mas não pertence a ela:
mora em `/report/custom-reports`, sem navegação lateral, como guia independente.
Três peças fazem isso funcionar:

1. `config/routes/custom_report_ui.rb` — `/report` e `/report/*path` servem o
   mesmo HTML de `desktop#index`. O curinga existe para o refresh não dar 404.
2. `app/frontend/apps/desktop/router/index.ts` (upstream) — a base do history era
   a string fixa `'desktop'`. Agora deriva do primeiro segmento do path, restrita
   a uma lista de pontos de montagem conhecidos (`desktop`, `report`), para a URL
   não poder definir base arbitrária. Sem isso o roteador não casa a rota e a
   página abre vazia.
3. `export const isMainRoute = true` no `routes.ts` da página — coloca a rota em
   `mainRoutes`, fora do wrapper `LayoutPage`, que é quem renderiza a sidebar.

A página tem casca própria (`components/CustomReportPage.vue`) em vez de
`LayoutContent`: `LayoutContent` depende do grid e das composables da navegação
lateral, que não existem fora de `LayoutPage`.

O item do menu Relatórios aponta para essa URL, e não para uma rota hash do SPA
legado. **Isso é obrigatório, não estético:** abrir uma segunda instância do SPA
legado faz `_plugin/session_taken_over.coffee` mandar `session_takeover` no
`ws:login`, e o backend (`Sessions.send_to`) derruba a aba original com "Uma nova
sessão foi criada com a sua conta". A Desktop View não participa desse mecanismo.
A rota legada `#report/custom` continua registrada apenas para redirecionar links
antigos (notificação de "relatório pronto").

Arquivos ATS puros (sem risco em sync): `app/models/custom_report.rb`,
`app/models/custom_report_run.rb`, `app/models/custom_report/{query,columns,result}.rb`,
`app/models/custom_report/exporter/csv.rb`,
`app/jobs/custom_report_generate_job.rb`,
`app/controllers/custom_reports_controller.rb`,
`config/routes/custom_report.rb`, as migrations `20260728120000..3`,
`20260729000000`, `20260729010000`, `20260729020000`,
`app/graphql/gql/types/custom_report_type.rb`,
`app/graphql/gql/types/custom_report_run_type.rb`,
`app/graphql/gql/types/custom_report/*.rb`,
`app/graphql/gql/queries/custom_report/{list,results,runs}.rb`,
`app/graphql/gql/mutations/custom_report/generate.rb`,
`app/frontend/apps/desktop/pages/custom-report/**`,
`app/frontend/apps/desktop/entities/custom-report/**`,
`app/assets/javascripts/app/models/custom_report.coffee`,
`app/assets/javascripts/app/controllers/custom_report.coffee`,
`app/assets/javascripts/app/controllers/report/custom.coffee`.

**Arquivos do upstream tocados — reaplicar se o upstream mexer neles:**

| Arquivo | Mudança e motivo |
|---|---|
| `app/models/online_notification_standalone.rb` | `kind` é validado contra lista fixa; sem acrescentar `custom_report` a notificação de "pronto" levanta exceção. Também define `CustomReportData`. |
| `app/graphql/gql/types/online_notification_standalone_type.rb` | O `case object.kind` em `#data` precisa do ramo `custom_report`. O campo é **non-null**: sem o ramo ele devolve nil e derruba a consulta de notificações **inteira**, não só a do relatório. |
| `app/graphql/gql/types/online_notification_standalone/data_union_type.rb` | `possible_types` precisa incluir `CustomReportDataType`, senão a union não resolve o payload. |
| `app/frontend/shared/entities/online-notification/graphql/queries/onlineNotifications.graphql` | Fragmento inline para `OnlineNotificationStandaloneCustomReportData`; sem ele o campo volta vazio. |
| `app/frontend/shared/composables/activity-message/activityMessageBuilder/builders/online-notification-standalone.ts` | `switch` no `__typename` cai em `default: return null` para tipo desconhecido, e o sino não mostra mensagem nenhuma. |
| `spec/factories/online_notification_standalone.rb` | Trait `:custom_report`, usada pelo spec de regressão do payload. |
| `app/frontend/apps/desktop/router/index.ts` | Base do history derivada do ponto de montagem, para o bundle servir `/report` além de `/desktop`. Era a string fixa `'desktop'`. |
| `app/assets/javascripts/app/models/online_notification_standalone.coffee` | `activityMessage` cai num `else` que devolve string de debug em inglês para `kind` desconhecido. Também define `uiUrl` para a notificação levar ao relatório. |
| `db/seeds/settings.rb` | Setting `custom_report_max_rows` (instalação nova não roda a migration). |
| `db/seeds/permissions.rb` | Todas as permissões ATS. Instalação nova não roda as migrations que as criavam, então o menu e o player simplesmente não apareciam. |

Nada em `app/assets/javascripts/app/views/navigation/*.jst.eco` foi alterado:
`navigation/personal.jst.eco` (que é quem renderiza `NavBarRight`, e não
`menu.jst.eco`) já honra `item.external` para gerar `target="_blank"`.

**Decisões que não são óbvias pelo código:**

- **Segurança:** o modelo salvo é uma consulta, nunca uma concessão.
  `CustomReport::Query` parte sempre do scope de permissão de **quem gera**
  (`TicketPolicy::ReadScope` e equivalentes) e só então aplica as condições.
  Isso é obrigatório porque **`Selector::Sql` não filtra por permissão** — ele
  só resolve pré-condições tipo "meus tickets". Os 3 níveis de visibilidade
  controlam quem vê o **modelo**, não o escopo dos dados. Coberto por spec
  explícito de vazamento.
- **Arquivo fora do `Store`:** `Store::File.add` recebe o conteúdo inteiro como
  String e o provider default pode ser `DB` — inviável para export grande.
  Os arquivos vão para `storage/custom_report_runs/`, que em Docker é o volume
  `zammad-storage`. Isso é **necessário**, não preferência: o job roda no
  container do scheduler e o download é servido pelo railsserver.
- **`store` só em `condition`:** a macro `store` do Zammad serve para Hash e
  converte um Array silenciosamente em `{}`. `columns`/`group_by`/`aggregations`
  são arrays e usam jsonb.
- **Progresso pelo WebSocket legado:** as subscriptions GraphQL usadas pelo bulk
  update do 7.2 só existem na Desktop View.
- **xlsx não usa `ExcelSheet`.** Ele recebe os registros como Array e monta a
  planilha inteira em memória, o que inviabiliza relatório grande.
  `CustomReport::Exporter::Xlsx` usa `WriteXLSX` direto com `constant_memory: 1`,
  modo em que cada linha vai para disco assim que a próxima começa. O teto de
  `MAX_ROWS = 1_048_575` é do **formato**, não da memória: uma planilha xlsx não
  passa disso, e acima o arquivo abriria truncado sem avisar — então a geração
  falha com mensagem clara e aponta o CSV. Números vão como número
  (`write_number`), o resto como texto: as colunas já chegam formatadas, e o
  `write_xlsx` interpretaria uma string como "1-2" como data.
- **Totalizadores: dois campos, não pares.** `aggregations` guarda as funções e
  `aggregation_attributes` os campos; `CustomReport::Summary` faz o produto dos
  dois. Assim o formulário de configuração usa componentes que já existem, sem
  precisar de um elemento de UI próprio para editar pares função+campo. `count`
  não usa campo e entra uma vez só.
- **A agregação roda sobre os ids, não sobre a relação.** `query.relation` carrega
  `distinct` e possivelmente joins vindos das condições; um `SUM` direto contaria
  o mesmo registro uma vez por linha duplicada pelo join.
  `CustomReport::Summary#base` faz `where(id: relation.select(:id))`, o que dá um
  registro por linha sem abrir mão do recorte de permissão.
- **Função e atributo da agregação entram no SELECT.** Validados antes: função
  contra `FUNCTIONS`, atributo contra as colunas reais do objeto, e `sum`/`avg`
  exigem coluna numérica. Combinação inválida é descartada em silêncio (não
  levantada), para um modelo salvo cujo campo mudou de tipo ainda gerar o resto do
  relatório. Coberto por spec, inclusive com função inválida.
- **Os nomes das relações no agrupamento são resolvidos só para os ids presentes**
  no resultado. Carregar a tabela relacionada inteira traria a base de usuários
  completa ao agrupar por proprietário.
- **`MAX_GROUPS = 1_000`:** agrupar por atributo de alta cardinalidade (título)
  geraria praticamente uma linha por registro.
- **Migrations com `up`/`down` explícitos:** a reversão automática do Rails
  falhava tentando remover índices que o `drop_table` já leva.
- **`global_id_field :id` nos tipos GraphQL:** `CustomReportType` e
  `CustomReportRunType` **não podem** declarar `field :id, GraphQL::Types::ID`.
  As consultas e a mutation resolvem o objeto com
  `Gql::ZammadSchema.verified_object_from_id`, que só entende o ID global
  (`gid://zammad/CustomReport/7`). Com o id cru a tela devolvia `"7"` e nada era
  encontrado — a tela de visualização não carregava dado nenhum. Há spec de
  regressão em `spec/graphql/gql/queries/custom_report/list_spec.rb` que faz o
  round-trip.
- **`CustomReport` inclui `CanSearch` + `CanSelector`:** a tela de configuração
  usa `App.ControllerGenericIndex` com `pagerAjax`, que pagina pelo endpoint
  `/api/v1/custom_reports/search`. Sem esses concerns o modelo não responde a
  `.search` e a tela devolve 404 e nunca carrega. `CanSelector` entra porque
  `CanSearch#search_sql_base` chama `selector2sql`. `HasSearchIndexBackend` fica
  **de fora** de propósito, para a busca sempre rodar no banco e não depender do
  Elasticsearch. A rota de `search` precisa vir **antes** de
  `/custom_reports/:id`, senão `'search'` é lido como id.
- **`#search` é restrito a `admin.custom_report`:** devolve todos os modelos,
  inclusive inativos e de outros usuários. Quem só tem `report.custom` usa
  `#index`, que aplica a visibilidade.
- **`CustomReportRun.enqueue!` é o ponto único de enfileiramento**, usado pela
  API REST e pela mutation GraphQL, para as duas rotas concordarem sobre formato
  padrão e nome de arquivo.
- **Download fora do GraphQL:** `download_path` devolve o caminho **relativo ao
  `api_path`**, consumido por `<CommonLink rest-api>`. O arquivo é servido por
  `send_file` num GET autenticado por cookie de sessão, porque pode ser grande.
- **Progresso na tela Vue por polling:** um `setInterval` de 4s que só roda
  enquanto existe execução `pending`/`running`. Não há subscription GraphQL para
  esta feature.
- **`errorMessage` mapeia a coluna `error`:** o tipo usa
  `field :error_message, String, method: :error`. A coluna do banco é `error`; sem
  o `method:` o GraphQL levanta "Failed to implement
  CustomReportRun.errorMessage" e a tela toda quebra. Coberto por spec, porque a
  primeira versão do spec não pedia esse campo e o bug passou.
- **O model CoffeeScript precisa de `@configure_overview`:** sem isso o
  `App.ControllerTable` levanta "overviewAttributes needed" e o grid de
  Gerenciar fica vazio.
- **`@configure` precisa listar todo atributo que o formulário envia:** o Spine
  monta o payload de gravação a partir dessa lista e descarta em silêncio o que
  faltar. `group_ids` e `enabled_filters` estavam fora, então grupos e filtros
  habilitados nunca eram salvos.
- **O operador do filtro é validado antes de chegar ao `Selector::Sql`.**
  `CustomReport::FilterDefinition::OPERATORS_BY_TYPE` define o que cada tipo
  aceita, e o resultado é intersectado com `Selector::Sql::VALID_OPERATORS` para
  ficar em sincronia com o upstream. Sem isso o operador vinha da requisição e ia
  direto ao construtor de SQL: um valor desconhecido levanta exceção (500), e um
  inesperado — `is set` num campo de texto — mudaria o significado do filtro.
  `CustomReport::Query#permitted_condition` descarta o que não passar.
- **`User` e `Organization` ficam fora de `ENUMERABLE_RELATIONS` de propósito.**
  O tipo de filtro é derivado da relação do atributo, e para relações pequenas
  (estado, prioridade) a lista inteira vai como opção de select. Cliente e
  organização continuam como texto: listar a base seria problema de volume e de
  privacidade — quem atende um grupo passaria a enxergar a carteira inteira.
  Grupo é select, mas recortado por `group_ids_access('read')`.
- **Valor em branco é comparado com `nil` e `''`, não com `blank?`:** um filtro
  booleano em `false` é `blank?` e seria descartado.

### Traduções pt-BR das customizações (`i18n/ats.pt-br.po`)

As strings customizadas ficam num arquivo **separado**, nunca em
`i18n/zammad.pt-br.po`.

`Translation.po_files_for_locale` faz `Dir.glob 'i18n/*.pt-br.po'` e devolve
`zammad.pt-br.po` primeiro, depois os demais em ordem alfabética. Como
`strings_for_locale` monta um Hash na ordem de leitura, o arquivo lido depois
sobrescreve entradas repetidas. Resultado: `i18n/ats.pt-br.po` vence, e um sync
com o upstream pode substituir `zammad.pt-br.po` por completo sem perder nada.

Armadilhas do formato:

- O parser (`simple_po_parser`) **não aceita comentário solto** seguido de linha
  em branco — ele espera um `msgid` depois do comentário. Comentários de seção
  precisam ficar colados no `msgid` seguinte, como `#.`.
- `"` dentro de `msgid`/`msgstr` precisa ser escapado (`\"`).

Para aplicar: `db/seeds.rb` já roda `Translation.sync` em instalação nova. Para
instalação existente, a migration `20260729020000_sync_ats_translations.rb` roda
`Translation.sync_locale_from_po('pt-br')` (só pt-br: sincronizar todos os
locales levaria minutos sem benefício). Manualmente:
`rails zammad:translations:sync`.

Ao adicionar uma string traduzível em código customizado, acrescente o `msgid` ao
`i18n/ats.pt-br.po` também.

### Botão de copiar número do ticket em listas de tickets (12/08/2026)

Ícone de copiar ao lado do número em toda lista renderizada por
`app/assets/javascripts/app/views/generic/ticket_list.jst.eco` — balão de
"Tickets abertos/fechados" do cliente/organização (ticket zoom), Tickets
relacionados, e tickets vinculados da base de conhecimento. Ícone fica **fora**
do `<a>` da linha, para o clique não também navegar para o ticket.

Arquivos ATS puros: `app/assets/javascripts/app/controllers/_plugin/ticket_list_number_copy.coffee`.

**Arquivos do upstream tocados — reaplicar se o upstream mexer neles:**

| Arquivo | Mudança e motivo |
|---|---|
| `app/assets/javascripts/app/views/generic/ticket_list.jst.eco` | Acrescenta o ícone de copiar (dois `<span>` de estado, idle/done) dentro do bloco já existente `<% if @show_id: %>`. |
| `app/assets/stylesheets/zammad.scss` | Regras `.task .js-ticketListNumberCopy` (o botão) e `.ticket-number-copy-header .ticket-number` (número maior/em negrito na barra compacta que aparece quando a sidebar de abas está recolhida — mesmo destaque que `.task-subline .ticket-number-copy` já tinha, mas em elemento e template diferentes, então precisou de regra própria). |

**Decisões que não são óbvias pelo código:**

- **Delegação global no `document`, não `events` de controller.** O balão de
  "Tickets abertos/fechados" é um popover do Bootstrap injetado direto no
  `<body>` por `App.PopoverProviderAjax#replaceOnShow` — não existe controller
  Spine dono daquele HTML, então um `events:` normal nunca dispararia ali. A
  mesma delegação cobre os outros três lugares que reaproveitam o template.
- **Troca de ícone via duas `<span>` pré-renderizadas, não `@Icon(...)` chamado
  do JS.** `@Icon` só existe dentro do contexto de render de um controller; fora
  disso (como no handler global) não há como chamar. O clique só alterna a
  classe `hide` entre os dois estados já prontos no template.
- **`<%# %>` de uma linha só.** Eco não aceita comentário `<%# %>` que quebra em
  mais de uma linha — já documentado abaixo, e reincidiu ao escrever este
  código; `assets:precompile` é quem pega isso, `coffeelint` não está disponível
  neste ambiente.

### Campos customizados de Organização já usados em produção (12/08/2026)

19 campos de `Organization` (texto/textarea) que já existiam em produção
(criados manualmente em Gerenciar > Objetos) mas nunca tinham sido capturados
no código — instalação nova, ou este ambiente de teste, ficava sem eles.
Agora criados automaticamente, de forma idempotente (só cria o que ainda não
existe), tanto no seed (instalação nova) quanto numa migration (instalação já
em produção, onde o seed não roda de novo): `razaosocial`, `cpf`, `cnpj`,
`codcliente`, `perfildeacesso`, `classificacao`, `cep`, `endereco`, `numero`,
`complemento`, `bairro`, `cidade`, `estado`, `pais`, `observacao` (textarea),
`grupoeconomico`, `unidaderesponsavel`, `nomegrupoeconomico`, `email`.

**Pendente**: `segmento` (select), `modulos` (multiselect) e `codrota`
(select) ficam de fora até termos a lista real de opções já configuradas em
produção — inventar valores aqui poderia divergir do que está em uso e
`ObjectManager::Attribute.add` sobrescreve config de campo já existente.

Arquivos ATS puros (nenhum arquivo do upstream foi tocado):

- `db/seeds/organization_custom_attributes.rb` — cria os campos num banco
  novo. Separado de `db/seeds/object_manager_attributes.rb` (100% stock do
  Zammad) de propósito, para não aumentar risco de conflito num sync.
- `db/migrate/20260812150000_add_organization_custom_attributes.rb` — mesma
  criação para instalações já em produção. Só roda se `system_init_done`
  existir (senão a própria instalação nova ainda vai rodar o seed).

**Arquivo do upstream tocado — reaplicar se o upstream mexer nele:**

| Arquivo | Mudança e motivo |
|---|---|
| `db/seeds.rb` | Acrescenta `organization_custom_attributes` na lista `seeds` (ordenada manualmente, não é glob de diretório), logo depois de `object_manager_attributes`. |

**Decisões que não são óbvias pelo código:**

- **Guard com `ObjectManager::Attribute.exists?` antes de todo `.add`.**
  `.add` não é idempotente: se já existe um registro com o mesmo
  `(object_lookup_id, name)`, ele **atualiza** em vez de ignorar — chamar sem
  guard num campo já em produção poderia alterar configuração real (mais
  arriscado ainda em select/multiselect, daí os 3 campos pendentes ficarem de
  fora).
- **`created_by_id: 1, updated_by_id: 1` explícitos.** Sem usuário autenticado
  no contexto de seed/migration isolado (`UserInfo.current_user_id` vazio), a
  validação do model falha com "Created by must exist, Updated by must
  exist".
- **`__()` só no seed, nunca na migration.** Regra própria do projeto
  (`Zammad/ForbidTranslatableMarker`): strings traduzíveis devem ser marcadas
  onde são definidas — isto é, no seed. Na migration os mesmos `display:`
  usam string literal simples.

### Busca e perfil de "Grupo Econômico" (12/08/2026)

5º grupo na busca global (além de Tickets/Clientes/Organizações/Base de
Conhecimento), agrupando organizações pelo campo customizado
`Organization#nomegrupoeconomico` (o nome legível do grupo — `grupoeconomico`
é só o código interno, não serve pra busca). Ao digitar um nome de grupo que bate, aparece
com ícone próprio; ao clicar, abre uma tela de perfil nova mostrando as
organizações daquele grupo (clicáveis, abrem o perfil normal da organização)
e os tickets abertos/fechados + gráfico de frequência agregados de **todas**
as organizações do grupo, no mesmo layout do perfil de organização.

Arquivos ATS puros (nenhum arquivo do upstream foi tocado):

- `app/controllers/economic_groups_controller.rb` + `config/routes/economic_groups.rb`
  — `GET /api/v1/economic_groups/search?query=` (nomes de grupo que batem,
  com contagem de organizações) e `GET /api/v1/economic_groups/show?name=`
  (organizações daquele grupo). Exige permissão `ticket.agent` (mesma exigida
  pelo perfil de organização) — qualquer agente vê, não só admin.
- `app/assets/javascripts/app/controllers/economic_group_profile.coffee` +
  `app/assets/javascripts/app/views/economic_group_profile/index.jst.eco` —
  tela de perfil, seguindo o mesmo padrão de
  `app/assets/javascripts/app/controllers/organization_profile.coffee`
  (Router + `App.TaskManager.execute` + widget `App.TicketStats`), trocando a
  lista de membros (pessoas) por organizações.
- `public/assets/images/icons/economic-group.svg` — ícone novo (3 círculos
  sobrepostos), inserido manualmente em `public/assets/images/icons.svg` e em
  `app/assets/stylesheets/svg-dimensions.css` (ver decisão abaixo).

**Arquivos do upstream tocados — reaplicar se o upstream mexer neles:**

| Arquivo | Mudança e motivo |
|---|---|
| `app/assets/javascripts/app/lib/app_post/global_search.coffee` | Depois de montar o resultado normal do `/search`, busca `/economic_groups/search` e injeta um grupo sintético `result['EconomicGroup']` antes de renderizar — sem participar de `Models.searchable`/`CanSearch`, que são só pra models reais. |
| `app/assets/javascripts/app/controllers/widget/ticket_stats.coffee` | `App.TicketStats` ganhou um 3º modo `organizationIds` (array), além dos já existentes `user`/`organization` (só 1). Sem assinatura/observação (não tem 1 registro pra observar), só dispara `load()` direto. O backend (`Ticket::Stats`) já aceitava array de `organization_id` desde sempre (usado pra somar tickets de todas as organizações de um cliente) — não precisou mudar nada no Ruby. |

**Decisões que não são óbvias pelo código:**

- **Grupo econômico é sintético, não um "model pesquisável".** `nomegrupoeconomico`
  é só uma coluna de texto repetida em várias `Organization` — não tem
  tabela própria. Por isso não dá pra usar o mecanismo padrão de busca
  (`Models.searchable`, que espera um ActiveRecord real com `assets`,
  `search_preferences` etc.) nem a busca nova em Vue (união GraphQL fixa em
  `Ticket/User/Organization`, `app/graphql/gql/types/search_result/item_type.rb`).
  Solução: endpoint próprio + merge manual no resultado do JS, ver acima.
- **`icons.svg`/`svg-dimensions.css` editados à mão, não via `gulp build`.**
  Rodar `pnpm exec gulp build` em `public/assets/images/` (processo oficial,
  ver `public/assets/images/README.md`) recompila **todo** o sprite com uma
  versão de `svgmin` diferente da que gerou o arquivo commitado, reformatando
  as ~200 entradas existentes (quebra de linha, ordem de atributos) — um diff
  de ~1800 linhas para adicionar 1 ícone, e ainda com bug (`icon-loading`/
  `icon-logo`/`icon-spinner-small` saíram com dimensão errada, 90x35).
  Extraído só o `<symbol>` novo do resultado do gulp e colado manualmente no
  meio do arquivo original — mesmo padrão de string (sem `fill` explícito,
  cor vem do CSS via `fill: currentColor`).
- **Ícone é fill puro (3 círculos), não usa `stroke`.** Nenhum ícone existente
  no sprite usa `stroke` visível (todos são formas preenchidas) — um ícone com
  linha/traço arriscava não herdar cor nenhuma do CSS do jeito esperado. Times
  de círculos sobrepostos segue o mesmo padrão de todo o resto do sprite.
- **Endpoint usa `GET .../show?name=` em vez de `GET .../:name`.** O "id" do
  grupo é o próprio nome (string arbitrária, pode ter espaço/acento/barra) —
  passar como query param evita qualquer problema de roteamento com
  caracteres especiais, sem precisar de constraint de rota.
- **`system_init_done` estava `false` no banco de dev local usado para
  testar.** Isso trava a SPA na tela de "Getting Started" pra qualquer
  visitante anônimo (não é bug desta feature) — corrigido só neste ambiente
  de teste com `Setting.set('system_init_done', true)`, não é uma mudança de
  código.

**Correções pós-primeiro teste visual (12/08/2026):**

- Ícone com 3 círculos **sobrepostos** ficava uma mancha borrada em 16px —
  trocado por 3 círculos **separados** (com espaço entre eles) em
  `economic-group.svg`/`icons.svg`.
- A aba (task) do perfil de grupo ficava travada no ícone de "loading" pra
  sempre — `EconomicGroupProfile#meta()` nunca setava `iconClass`, e
  `App.TaskManager` usa `'loading'` como valor padrão até o controller
  informar o ícone real (`app/assets/javascripts/app/lib/app_post/task_manager/singleton.coffee:54`).
  Adicionado `iconClass: 'economic-group'` no `meta()`.

### Contador de tickets por agrupamento e botão de atualizar na Visão Geral (14/08/2026)

Duas melhorias na tela de Visão Geral (`#ticket/view/:view`) quando ela está
com agrupamento ativo (ex.: agrupar por proprietário):

1. **Contador ao lado do nome do grupo** (ex.: "Débora Carvalho (4)"). Essa
   feature já existe **nativa** no Zammad (`App.ControllerTable#renderTableGroupByRow`),
   mas vem desligada de fábrica atrás de um setting cujo título no admin
   (`'Open ticket indicator'`) não tem nada a ver com o que ele faz — por isso
   é praticamente impossível de achar/ligar pela UI. Ligado por padrão neste
   fork via seed + migration.
2. **Botão "Atualizar"** ao lado de "Opções", recarrega a lista da visão geral
   sem recarregar a página inteira (reaproveita `App.OverviewListCollection.fetch`,
   o mesmo mecanismo que "Opções" já usa ao salvar).

Arquivos ATS puros: `db/seeds/ats_settings.rb` (settings nativos que o fork
liga por padrão — separado de `db/seeds/settings.rb`, que é 100% stock),
`db/migrate/20260814120000_enable_table_group_by_show_count.rb`.

**Arquivos do upstream tocados — reaplicar se o upstream mexer neles:**

| Arquivo | Mudança e motivo |
|---|---|
| `db/seeds.rb` | Acrescenta `ats_settings` na lista `seeds`, logo depois de `settings`. |
| `app/assets/javascripts/app/controllers/_application_controller/table.coffee` | `renderTableGroupByRow` recontava `@objects` inteiro (um loop `for` completo) **uma vez por grupo renderizado** — O(n × grupos), com `groupObjectName` (usa `App.viewPrint`, não é barato) chamado a cada iteração. Numa fila de centenas de tickets isso trava a cada re-render, e a Visão Geral re-renderiza a cada push de WebSocket. Trocado por um `_.countBy` calculado uma vez em `renderTableRows` (guardado em `@groupByCounts`), e `renderTableGroupByRow` só faz um lookup O(1). Contagem sobre `@objects` (lista completa), não a página atual, pra não mudar com paginação — mesma semântica de antes. |
| `app/assets/javascripts/app/views/agent_ticket_view/content.jst.eco` | Acrescenta o botão `.js-overviewRefresh` fora do `<% if @edit: %>` (esse é só admin) — visível pra qualquer agente. |
| `app/assets/javascripts/app/controllers/ticket_overview/table.coffee` | Novo evento `click [data-type=refresh]` + método `refresh`/`refreshDone`. |
| `i18n/ats.pt-br.po` | `"Refresh"` não tinha tradução pt-BR nativa em nenhum catálogo do Zammad — adicionada aqui. |

**Decisões que não são óbvias pelo código:**

- **Botão de atualizar se reabilita por tempo (2s), não esperando o callback
  de dados.** Se o `fetch` falhar (rede caiu, etc.), `App.OverviewListCollection`
  nunca dispara o callback de `updateTable` — esperar por ele deixaria o botão
  travado pra sempre numa falha. O `@delay` também evita spam de cliques.
- **Contagem usa `@objects` (lista completa carregada), não `objectsToShow`
  (página atual).** Preserva o comportamento original: o total do grupo não
  muda dependendo de qual página da paginação você está vendo.
- **Setting `ui_table_group_by_show_count` ligado só se `system_init_done`
  existir, na migration.** Mesmo motivo de sempre: instalação nova quem liga
  isso é o seed; a migration é só pra quem já está em produção.
- **Não foi possível rodar o spec de sistema que cobre esse contador
  (`spec/system/ticket/view_spec.rb:401`, contexto `ui_table_group_by_show_count`)
  neste ambiente de dev — Chrome/chromedriver não estão instalados no
  container `zc-run`.** Verificado por outra via: reproduzido o algoritmo
  antigo (recontagem por loop) e o novo (`_.countBy`) em Node com os mesmos 4
  tickets/3 grupos do spec (`''`, `'key_1'` ×2, `'key_2'`) — resultado idêntico
  em todos os grupos. Também rodou de verdade contra o banco de teste (limpo)
  até a suíte tentar abrir o Chrome, então o seed/reset em si (truncate +
  migrate + seed) foi validado de ponta a ponta.

## Referências

- Repositório original: https://github.com/zammad/zammad
- Documentação Zammad: https://docs.zammad.org/
- Branch customizada: `custom-branding-ats`

