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
7. **Aviso de fim de pausa**: alerta visual e sonoro antes do tempo limite (ver abaixo)

#### Aviso antes do fim da pausa (15/08/2026)

Alerta para o colaborador não perder a hora de voltar. Dispara quando faltam N
minutos para o tempo limite: notificação no topo + cronômetro da barra piscando
em âmbar + som.

- **Antecedência é por tipo de pausa**: coluna nova `pause_types.warning_minutes`
  (migration `20260815120000`). Em branco desliga o aviso para aquele tipo, que
  é o comportamento de antes — nenhum tipo existente passa a avisar sozinho.
- **Som liga/desliga** pelo setting `pause_control_warning_sound`
  (`db/seeds/ats_settings.rb` + migration `20260815120100`), default ligado.
  Usa `assets/sounds/Bell.mp3`, que já vem no Zammad.

Arquivos: `app/models/pause_type.rb`, `app/controllers/pause_types_controller.rb`,
`app/assets/javascripts/app/models/pause_type.coffee`,
`app/assets/javascripts/app/controllers/user_status_bar.coffee`,
`app/assets/stylesheets/zammad.scss`.

**Decisões que não são óbvias pelo código:**

- **O timer da barra deixou de PARAR com a aba em segundo plano; passou a rodar
  a cada 5s.** Ele parava para poupar CPU, mas quem está em pausa quase sempre
  deixou a aba escondida — com o timer parado o aviso nunca dispararia,
  justamente no cenário em que ele mais serve. Ver `onVisibilityChange`.
- **A "já avisei" é o id da pausa, não um booleano.** Duas pausas em sequência
  reusam o mesmo controller; com booleano, a segunda herdaria o aviso da
  primeira e ficaria muda.
- **A janela do aviso fecha no tempo limite.** Passou do limite, o aviso perde a
  função: aí já existe o fluxo de justificativa de atraso, que é mais forte.
- **`warning_minutes` precisa ser menor que `time_limit`, e não pode existir com
  limite ilimitado (`time_limit` 0).** Avisar "faltam 10" numa pausa de 5 nunca
  dispararia, e sem fim definido não há o que antecipar — validado no model, com
  mensagem em vez de silêncio.
- **Som dentro de `try`.** Navegador bloqueia áudio sem interação prévia do
  usuário; o aviso visual cobre o caso, e uma exceção aí não pode derrubar o
  timer.
- **`prefers-reduced-motion` desliga o piscar**, mantendo a cor: o destaque
  continua, sem animação para quem pediu menos movimento no sistema.
- **A migration da coluna NÃO tem o guard de `system_init_done`** usado nas
  outras migrations ATS. Aquele guard existe para migrations que reaplicam dados
  que o seed já cria; esta cria coluna, e pular numa instalação nova deixaria o
  schema incompleto.

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

#### Colunas de atendimento em curso e destaque de linha (15/08/2026)

O painel ganhou três colunas — **Tempo de atendimento**, **Número do ticket** e
**Organização** — preenchidas quando o colaborador tem uma contagem de tempo
correndo (`TicketTimeTracking.active`). E as linhas de quem está em pausa,
offline ou deslogado passaram a ter destaque na linha inteira.

Arquivos: `app/controllers/public_pause_indicators_controller.rb`,
`app/views/public_pause_indicators/page.html.erb`,
`app/assets/javascripts/app/public_pause_indicators.coffee` (todos ATS puros) e
`app/models/ticket_time_tracking.rb` (ver invalidação de cache abaixo).

**Decisões que não são óbvias pelo código:**

- **O tempo vai em duas partes: `tracking_total_seconds` (acumulado
  persistido) + `tracking_started_at` (início do trecho corrente).** O navegador
  soma os dois a cada segundo, como já fazia com o tempo de pausa. Mandar um
  total pronto congelaria o cronômetro entre um refresh e outro; mandar só o
  instante de início zeraria a contagem a cada retomada, já que um atendimento
  costuma passar por várias pausas.
- **`TicketTimeTracking#broadcast_state_change` passou a chamar
  `PauseIndicatorsBroadcast.broadcast_change`.** Sem isso o painel só era
  notificado (e o cache só invalidado) em eventos de PAUSA — iniciar ou trocar
  de atendimento não avisava ninguém, e as colunas novas ficariam paradas até o
  cache expirar (`PauseIndicatorsCache::TTL_SECONDS`, 60s). O broadcast está
  dentro de `rescue` porque um painel indisponível não pode derrubar o
  salvamento de uma contagem de tempo.
- **Batch load das contagens, com `includes(ticket: :organization)`.** As
  colunas mostram ticket e organização; sem o includes seriam duas queries por
  usuário. Medido: `build_public_entries_full` faz **5 queries fixas**,
  independente da quantidade de colaboradores.
- **Rótulo "Número do ticket", não "Ticket".** `Ticket` já existe no catálogo
  oficial pt-BR e sairia como "Tíquete".
- **Destaque com borda lateral além de cor de fundo.** O painel roda em TV: o
  ponto colorido de 10px da primeira coluna não se lê de longe. Em pausa vence
  offline na precedência, por ser a informação mais específica (quem está em
  pausa também tem `state` diferente de `online`).

**Exposição de dados — decidido com o usuário (15/08/2026):** a rota
`/monitor/pause_indicators` **não tem autenticação** (`PublicPauseIndicatorsController`
não chama `authentication_check`), então número de ticket e nome de organização
ficam visíveis para qualquer um com o link. Isso foi levantado antes de
implementar e o usuário confirmou que o painel é de uso interno.

Vale notar a tensão: `TicketTimeTracking#broadcast_to_ticket_watchers` tem um
comentário explicando que ele evita `Sessions.broadcast` aberto justamente para
um cliente não descobrir "qual atendente está em qual ticket e há quanto tempo".
O painel agora publica exatamente isso, sem login. **Se um dia esse link sair da
rede interna, reavaliar** — as opções levantadas na época foram: omitir a
organização, mostrar só o tempo, ou exigir autenticação na página.

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

#### Pausa manual removida; pausa/retomada seguem o controle de pausas (14/08/2026)

O atendente não pausa mais a contagem por conta própria. O botão de pausar saiu
do player, e a contagem agora só para por eventos do sistema de pausas:

| Evento | O que acontece com a contagem |
|---|---|
| Entrar em pausa, ou ficar offline | Pausa, e **retoma sozinha** ao encerrar a pausa / voltar a ficar online |
| "Deslogar" no controle de pausas | Pausa e **não** retoma sozinha — nem ao logar de novo; volta só com um clique em Iniciar |
| Fechar o ticket | Continua encerrando, como já era (`Ticket#end_time_tracking_on_close`) |
| Iniciar contagem em outro ticket | Segue igual: pergunta e transfere (`switchTracking`) |

Arquivos (todos já eram tocados pela feature):
`controllers/ticket_zoom/time_tracking.coffee`,
`views/ticket_zoom/time_tracking.jst.eco`, `stylesheets/zammad.scss`.

Removidos: botão `.js-tt-pause` (markup, `elements`, `events`), `onPauseClick`,
`pauseTracking`, `canPause`, o bloco do botão em `updateButtonStates` e a regra
CSS `.js-tt-pause.is-ready`. O auto-pause (`autoPauseTracking`) **já existia** e
foi mantido; o que faltava era o caminho de volta.

**Decisões que não são óbvias pelo código:**

- **`blockAutoResume` é estado de tela, não do banco.** Não existe campo que
  distinga "pausado por logout" de "pausado por pausa comum" — logout nem cria
  `UserPause` (é `UserPauseSession`, outro conceito). O que distingue os casos é
  o evento do frontend: `pause_control:logout` é disparado separadamente de
  `pause:started`/`user_state:changed` (ver `user_status_bar.coffee`). Daí a
  flag viver no controller do player.
- **Só um clique manual em Iniciar limpa a flag.** É o que garante "quando ele
  iniciar vai ter que clicar no botão": logar de novo dispara
  `pause_control:login`, que não mexe na flag.
- **`maybeAutoResume` delega o resto a `canResume`.** Ticket fechado, permissão,
  dono do ticket e o próprio estado de pausa/offline já são checados lá — repetir
  isso na retomada automática só criaria duas regras para divergirem depois.
- **`UserPauseService#end_pause` já devolve `resume_tracking`/`tracking_id`, e
  segue sem consumidor.** A retomada foi feita no frontend, junto do auto-pause
  que já morava lá, em vez de mover metade da regra para o backend.

#### Bug: retomava o ticket errado com dois abertos (14/08/2026)

Relato do usuário: inicia contagem no ticket A, inicia no B (troca — pausa A
automaticamente, como já era o esperado). Fica offline, volta a ficar online.
**Os dois** retomam — inclusive A, que devia continuar pausado.

Causa: `App.TicketZoomTimeTracking` existe **uma instância por aba de ticket
aberta**, e todas escutam o mesmo evento global `user_state:changed`. O guard de
`maybeAutoResume` só verificava "este ticket está pausado e pode retomar"
(`canResume`) — verdadeiro tanto para B (pausado pela troca de estado) quanto
para A (que já estava pausado antes, por causa da troca de ticket, sem relação
nenhuma com ficar offline). Ao voltar online, as duas abas decidem retomar.

Correção: nova flag `@autoPaused`, só `true` enquanto a pausa **desta aba**
tiver sido causada pelo próprio `autoPauseTracking` (offline/pausa/deslogar).
`maybeAutoResume` passou a exigir a flag além do `canResume`. Pausa por troca de
ticket (`switchTracking`, chamado pela OUTRA aba) nunca marca a flag nesta —
por isso A não tenta mais retomar.

**Decisões que não são óbvias pelo código:**

- **A flag não é zerada no ramo "pausado" de `onTimeTrackingStateChange` (o
  evento de WebSocket) nem no ramo equivalente de `checkCurrentTracking`.**
  `autoPauseTracking` já marca a flag `true` no próprio `success`, e o mesmo
  pause que ele causa dispara esse evento de volta pro mesmo controller — zerar
  ali desfaria o que acabou de ser marcado, por causa da ordem de chegada das
  duas respostas assíncronas (a do `pause` e a notificação de estado). O valor
  padrão (`false`) já cobre sozinho o caso "pausado por outro motivo", sem
  precisar zerar em lugar nenhum.
- **Zerada em todo caminho que reativa a contagem** (`startTracking`,
  `resumeTracking`, `switchTracking`, clique manual em Iniciar, e os ramos
  `running`/`ended`/`inactive` do WebSocket): uma vez resolvido o motivo do
  auto-pause, a flag não deve sobreviver pro próximo ciclo.
- **Não foi possível escrever teste automatizado para isto.** É bug de
  coordenação entre múltiplas instâncias de controller reagindo ao mesmo evento
  global — precisaria de um spec de sistema com duas abas de ticket abertas
  simultaneamente, e este ambiente não tem Chrome/chromedriver (mesma limitação
  já documentada para o spec de contagem por grupo). Verificado rastreando a
  lógica manualmente linha a linha contra o cenário relatado.

#### Bug: sair da pausa não retomava a contagem (15/08/2026)

Relato: ficar offline e voltar online retomava a contagem, mas entrar em pausa e
sair **não**.

Causa da assimetria: `UserPauseService#start_pause` **já pausa** a contagem no
servidor (`active_tracking&.pause!`). O frontend, então, nem chegava a executar o
próprio `autoPauseTracking` — e era só ali que a marcação "pausei por
indisponibilidade" acontecia. Sem a marca, `maybeAutoResume` desistia ao sair da
pausa. Ficar offline não tem equivalente no backend: o frontend pausa sozinho,
marca, e por isso aquele caminho funcionava.

Correção: a decisão de retomar deixou de depender de **quem** pausou e passou a
usar `users.current_active_ticket_id`, que o servidor mantém e que `pause!`
**não** limpa — só encerrar ou trocar de ticket o move. Ver `isAutoResumable`.

**Decisões que não são óbvias pelo código:**

- **`current_active_ticket_id` resolve os dois bugs de uma vez.** É o mesmo
  critério que impede o "retoma o ticket errado" documentado acima: entre vários
  tickets pausados, só o que ainda detém o slot volta sozinho — um pausado por
  troca já entregou o slot a outro. Confirmado que o campo chega ao frontend
  pelos assets do usuário.
- **Sobrevive a recarregar a página no meio da pausa**, porque vem do servidor.
  A flag local `@autoPaused` sozinha se perderia no reload; ela ficou apenas
  como reserva para quando o campo não estiver disponível.
- **A marcação da flag passou a olhar o estado do usuário, não a origem do
  pause** (`in_pause`/`offline` no instante em que a contagem para). Trocar de
  ticket acontece com o usuário disponível, então não marca.

#### Correção da correção: 409/422 ao voltar da pausa (15/08/2026)

A tentativa acima ainda falhava com duas abas abertas:
`POST .../318/time_tracking/resume 409`, `.../259/time_tracking/resume 409` e
depois `422`. As duas abas tentavam retomar ao mesmo tempo.

Duas causas:

1. **`current_active_ticket_id` lido do usuário no navegador não é confiável.**
   O campo existe nos assets, mas o objeto `App.User.current()` nem sempre
   chega atualizado a todas as abas — com o valor velho (ou ausente) cada aba
   caía no fallback local e todas se achavam no direito de retomar. Passou a vir
   do servidor a cada consulta de estado: `is_user_active_ticket` em
   `TicketTimeTrackingsController#tracking_json`.
2. **A retomada automática usava o mesmo caminho de erro do clique manual.** Um
   409 ("outro ticket em atendimento") abria o **diálogo de troca de ticket**
   sozinho, sem ninguém ter clicado em nada, e o 422 virava alerta vermelho.
   `resumeTracking` ganhou o parâmetro `silent`: na retomada automática a falha
   só ressincroniza com o servidor.

**Decisões que não são óbvias pelo código:**

- **`is_user_active_ticket` é preservado ao reconstruir `@tracking` no evento de
  WebSocket** (`onTimeTrackingStateChange`): o push não carrega o campo, e sem
  preservar, o primeiro evento apagaria a informação que decide a retomada.
- **Falha de retomada automática não é erro do usuário.** Ele não pediu nada, e
  outro ticket já ter assumido a contagem é resposta legítima — daí o silêncio,
  não um toast.

### Gatilho: e-mail para os endereços guardados num campo (15/08/2026)

Permite pôr endereços num campo (ex.: "E-mails de aviso" da organização) e, com
a condição do gatilho satisfeita, notificar quem estiver lá.

O destinatário de um gatilho aceitava só uma lista fechada — cliente,
proprietário, agentes do grupo, usuário específico — e qualquer outro valor caía
no `else` e era descartado com log de erro
(`Ticket::PerformChanges::Action::NotificationEmail#recipients_by_type`). O
sistema de placeholders já resolvia `ticket.organization.campo` desde sempre,
mas nunca era aplicado ao destinatário, só a assunto e corpo — há inclusive um
comentário no upstream admitindo o desvio ("Small workaround to avoid
complicated code changes for placeholder support",
`_ui_element/_application_action.coffee`).

**Arquivos do upstream tocados — reaplicar se o upstream mexer neles:**

| Arquivo | Mudança e motivo |
|---|---|
| `app/models/ticket/perform_changes/action/notification_email.rb` | Novo `when` para `attribute::<caminho>` em `recipients_by_type`, resolvendo pelo mesmo renderizador do corpo. |
| `app/assets/javascripts/app/controllers/_ui_element/_application_action.coffee` | `recipientAttributeVariables` + grupo "Campos de e-mail" no seletor de destinatários. |

**Decisões que não são óbvias pelo código:**

- **Devolve ARRAY, não string.** `valid_recipient_address` só aproveita o
  primeiro endereço de cada string — um campo com três e-mails perderia dois.
  Como `recipients_raw` concatena arrays, devolvendo lista cada endereço é
  validado, deduplicado e checado individualmente, sem tocar no upstream.
- **Separadores aceitos: vírgula, ponto e vírgula e quebra de linha.** É campo
  digitado por gente, e cada um separa de um jeito.
- **Caminho que não resolve é descartado explicitamente.** O renderizador
  **não** levanta exceção: devolve o placeholder de volta anotado
  (`\#{ticket.organization.x / no such method}`). Sem o `include?('#{')` isso
  seguiria adiante como se fosse endereço. O `rescue` sozinho não bastava —
  descoberto testando com um campo inexistente.
- **Só campos do tipo E-mail aparecem na lista** (`tag: 'input'` +
  `type: 'email'`). Oferecer todo campo de texto encheria o seletor e convidaria
  a apontar para algo que não é endereço. Sem nenhum campo assim, o grupo nem
  aparece.
- **Grupo separado de "Variáveis"** porque estes dependem do que existe em
  Gerenciar > Objetos e variam de instalação para instalação.

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

### Mensagem de sucesso invisível no tema escuro (14/08/2026)

Ao gerar o relatório em CSV (que funciona), a notificação de "pronto para
baixar" aparecia como um balão vermelho **vazio** no topo. Não era falta de
tradução: a string existe e a notificação nativa do Chrome mostrava o texto
certo.

Causa: em `app/frontend/apps/desktop/styles/tokens.css`, o branding tinha
pintado toda a escala `green` de `#480404`. As classes de sucesso são
`bg-green-300 dark:bg-green-900 text-green-500`
(`app/frontend/apps/desktop/initializer/initializeGlobalComponentStyles.ts`,
linhas 21, 33 e 75 — valem para **selo, alerta e notificação**). No tema escuro
o fundo virava `green-900` e o texto `green-500`, os dois `#480404`: **mesma
cor**, texto invisível. De quebra, sucesso e erro ficavam ambos vermelhos.

Ou seja, o defeito não era do relatório: **toda** mensagem de sucesso da
Desktop View no tema escuro estava ilegível.

Correção: `green-300`, `green-500` e `green-900` voltaram aos valores originais
do Zammad. Só esses três — são os que compõem as classes de sucesso.
`green-400` **segue vermelho ATS**: ele não entra nessas classes (é indicador de
ticket fechado, resposta publicada da base de conhecimento e aba de ticket) e
ali não havia problema de leitura. Mexer nele mudaria o visual de coisas que
estão funcionando.

Regra que fica: cor de **status** (sucesso/erro/aviso) não deve ser
rebrandada junto com a paleta da marca — ela precisa contrastar com o próprio
fundo e distinguir-se do erro.

### Export xlsx quebrado: `set_constant_memory` (14/08/2026)

Toda geração em Excel falhava com
`undefined method 'set_constant_memory' for an instance of Writexlsx::Format`
(o CSV seguia funcionando).

Causa: `WriteXLSX.new(path, constant_memory: 1)`. O construtor da gem só trata
como **opção** as chaves de uma allowlist —
`tempdir date_1904 optimization excel2003_style strings_to_urls max_url_length`
(`write_xlsx-1.15.0/lib/write_xlsx/workbook/initialization.rb:116`). Qualquer
outra chave cai no `reject` da linha 122 e vira **propriedade do formato
padrão**, aplicada depois em `add_format` como `set_<chave>`. Ou seja, uma opção
inexistente não dá erro de argumento: vira uma chamada de método inexistente no
`Writexlsx::Format`, e só na hora de gerar.

Correção: remover a opção (`app/models/custom_report/exporter/xlsx.rb`).

**O comentário do arquivo estava errado e foi reescrito.** Ele afirmava que o
xlsx rodava em "constant_memory", com o custo de memória independente do volume.
Isso nunca foi verdade nesta gem: `Writexlsx::Worksheet::CellDataStore` guarda
as células num Array e só serializa no `close`, e a opção `optimization` é lida
(`initialization.rb:30`) e **nunca usada** em lugar nenhum da lib — não existe
modo de memória constante na 1.15.0. O mesmo comentário enganoso em
`app/jobs/custom_report_generate_job.rb` também foi corrigido. O que segura o
consumo é o teto de `MAX_ROWS`; streaming de verdade só no CSV.

Spec nova: `spec/models/custom_report/exporter/xlsx_spec.rb`. Não havia **nenhum**
teste de exportador — por isso o bug só apareceu em produção. A spec gera o
arquivo de verdade e confere a assinatura `PK` (xlsx é zip): mockar o WriteXLSX
teria deixado passar exatamente este erro, que é de integração com a gem.

### Filtros do relatório: rótulos em pt-BR e data como período (14/08/2026)

Dois ajustes na tela de visualização do relatório personalizado.

**1. Rótulos em português.** Filtros como "Close at" e "Last close at"
apareciam em inglês. A tradução já funcionava — faltavam as strings.

`CustomReport::Columns#display_for` traduz o rótulo do atributo, mas colunas de
ticket que **não são atributos do Object Manager** (`close_at`, `last_close_at`,
`first_response_at`, os `*_in_min`, etc.) não têm rótulo cadastrado e caem no
fallback `humanize`, que gera o texto em inglês (`close_at` → "Close at").
Traduzindo esse texto humanizado no catálogo, o mesmo fallback passa a devolver
português — sem tocar no código.

Levantadas **todas** as colunas de `tickets` nessa situação (não só as do
print): 22 rótulos novos em `i18n/ats.pt-br.po`.

**2. Filtro de data virou período.** Antes aceitava uma data só
(`after (absolute)`). Agora todo filtro de data rende **dois** campos (de/até)
e usa o operador nativo `in range`, que o `Selector::Sql` já implementa
(`lib/selector/sql.rb:586`): com os dois lados vira `BETWEEN`, com só um lado
vira `>=` ou `<=`. Filtrar um dia só é pôr a mesma data nos dois campos.

Arquivos ATS puros:

- `app/models/custom_report/filter_definition.rb` — `'date'` passou a aceitar
  `in range` (os operadores antigos seguem aceitos, para não quebrar filtro já
  montado).
- `app/models/custom_report/query.rb` — `normalize_filter_value`, ver decisão
  abaixo.
- `app/frontend/apps/desktop/pages/custom-report/components/CustomReportFilters.vue`
  — `fieldsFor` (plural) devolve os dois campos de data, e `dateRangeFilters`
  os remonta num filtro só ao aplicar.
- `i18n/ats.pt-br.po` + `db/migrate/20260814140000_sync_ats_translations_report_column_labels.rb`.

Nenhum arquivo do upstream foi tocado.

**Decisões que não são óbvias pelo código:**

- **Os dois lados vazios descartam o filtro, um lado vazio não.** O
  `Selector::Sql` levanta `"Invalid value in range"` quando recebe `['', '']`,
  o que derrubaria a tela inteira — e não só aquele filtro. Já um lado vazio é
  intencional ("sem limite deste lado"), então `normalize_filter_value` só
  descarta quando os dois estão em branco.
- **Rótulo composto montado no TypeScript, não no schema do FormKit.** O
  `display` já chega traduzido do backend; mandar "Fechado em (from)" inteiro
  para o FormKit traduzir não acharia entrada nenhuma no catálogo e o sufixo
  ficaria em inglês. Daí `i18n.t('%s (from)', filter.display)`.
- **O teste de troca de relatório passou a usar `findAllByLabelText`.** Um
  filtro de data agora rende dois campos, então `findByLabelText('Fechado em')`
  encontraria dois elementos e falharia. A regex também deixa o teste
  indiferente ao idioma do sufixo.
- **Validado**: `rspec spec/models/custom_report/{query,filter_definition}_spec.rb`
  (45 exemplos, 0 falhas), `vitest custom-report-switch.spec.ts` (6 passando),
  `pnpm lint:ts` (vue-tsc limpo), `pnpm lint:js` (nada nos arquivos deste lote)
  e `assets:precompile`. PO conferido por script: 177 pares
  `msgid`/`msgstr`, sem duplicados nem entrada malformada.
- **Se o rspec sair com código 1 e nenhuma saída**, o problema não está no
  código: falta o Postgres. `docker start zc-run` não sobe `zc-pg`/`zc-redis`, e
  sem banco o `rails_helper` morre calado — nem stdout nem stderr. Subir os três
  containers resolve.

## Referências

- Repositório original: https://github.com/zammad/zammad
- Documentação Zammad: https://docs.zammad.org/
- Branch customizada: `custom-branding-ats`

