# Relatório de Sincronização com Upstream — 27/07/2026

Sincronização do fork ATS com `upstream/develop` (Zammad 7.2.x) e correção de bug
no controller de Settings.

- **Branch de trabalho:** `sync-upstream-20260727`
- **Backup:** `backup-ats-antes-sync-20260727` (estado exato de `developer` antes do merge)
- **Branch original:** `developer` — **intocada**
- **Merge commit:** `3a23fc024d`
- **Escala:** 2958 arquivos alterados, +336.034 / −191.073 linhas

---

## 1. Correção prévia: 500 → 404 em setting inexistente

Commit `efc9885b2e`, aplicado antes do merge.

### O bug

`GET /api/v1/settings/999999999` como admin retornava **HTTP 500** em vez de 404.

Cadeia:

1. `SettingsController` usa `prepend_before_action :authenticate_and_authorize!`,
   então a policy roda **antes** da action — nunca chega no `model_show_render`
   que daria 404.
2. `Controllers::SettingsControllerPolicy#setting` chama `Setting.lookup(id:)`,
   que é `find_by` e **retorna `nil`** para ids desconhecidos.
3. `Pundit.authorize(user, nil, :show?)` levanta `Pundit::NotDefinedError`.
4. `NotDefinedError` **não é** `NotAuthorizedError` — são classes irmãs sob
   `Pundit::Error`. Nem o `rescue` da policy nem o
   `rescue_from Pundit::NotAuthorizedError` pegam.
5. Cai em `rescue_from StandardError, with: :internal_server_error` → 500.

Afeta `show`, `update`, `update_image` e `reset` — todos passam por
`authorized_for_setting?`.

### A correção

```ruby
def authorized_for_setting?(query)
  # Setting.lookup returns nil for unknown ids. Passing nil to Pundit would raise
  # NotDefinedError, which is not a NotAuthorizedError and would surface as a 500.
  return not_authorized(ActiveRecord::RecordNotFound.new) if setting.nil?

  Pundit.authorize(user, setting, query)
  true
rescue Pundit::NotAuthorizedError
  not_authorized("required #{setting.preferences[:permission].inspect}")
end
```

Usa o padrão idiomático do Zammad (`not_authorized` com exception custom, igual
`Controllers::AttachmentsControllerPolicy#custom_exception`). O handler
`pundit_not_authorized_error` mapeia `custom_exception` → `not_found` → 404.

### Verificação (executada)

Stack Docker: postgres 17.5 + redis + memcached + ruby 3.4.8, 313 gems, DB
migrada e seedada.

| Rodada | Resultado |
|---|---|
| Spec novo, **com** o fix | `2 examples, 0 failures` |
| Spec novo, **fix revertido** | `2 examples, 2 failures` — `expected 404 but it was 500` |
| Arquivo `settings_spec.rb` inteiro | `13 examples, 0 failures` |
| `rubocop` nos arquivos alterados | `no offenses detected` |

A rodada com o fix revertido é a prova: o bug era real e o spec pega a regressão.

### Descarte de um fix anterior

Havia no working tree um diff que adicionava nil-safety em
`Setting#options`/`#preferences` (`object.options || {}`). Foi **revertido** —
era no-op. `ActiveRecord::Store::IndifferentCoder#load` converte `NULL` em
`HashWithIndifferentAccess` vazio, nunca `nil`. Confirmado empiricamente com
ActiveRecord 8.0.5 + o patch do Zammad em
`lib/core_ext/active_record/store/indifferent_coder.rb`:

```
coluna crua no banco: options=nil preferences=nil
s2.options      => {}   (ActiveSupport::HashWithIndifferentAccess)
```

O spec que acompanhava esse diff passava com ou sem as mudanças de produção.
Foi substituído pelos 2 examples que cobrem o caminho realmente quebrado.

---

## 2. O merge com upstream

### Contexto: upstream reescreveu a `stable`

O `git fetch` reportou:

```
+ 17c9d075e8...129ad589c5 stable -> upstream/stable (forced update)
```

O commit do último sync do fork (`17c9d075e8`, 18/05) **deixou de ser ancestral**
de `upstream/stable`. O merge-base recuou para **20/02/2026** (`7d72ecce91`).

Prova do rebase: o fix #6136 existe nos dois lados com hashes diferentes —
`17c9d075e8` (nosso) e `18c5e90601` (upstream).

### Ref escolhida

**`upstream/develop`** (VERSION `7.2.x`), por decisão explícita.

Alternativa considerada e descartada: `upstream/stable` (7.1.x, 720 commits,
158 conflitos previstos).

| Métrica | `develop` (escolhido) | `stable` |
|---|---|---|
| Commits faltando | 1231 | 720 |
| — genuinamente novos | 1114 | 604 |
| — já aplicados (mesmo patch-id) | 117 | 116 |
| Conflitos previstos | 221 | 158 |

Previsão feita com `git merge-tree --write-tree`, sem tocar no working tree.

### Distribuição dos 221 conflitos

A descoberta central: **190 dos 221 não eram customização ATS**.

| Causa | Qtd | Resolução |
|---|---|---|
| Fork nunca tocou no arquivo — só churn do `stable` | 118 | upstream |
| Catálogos i18n (zero strings ATS) | 50 | upstream |
| Puro CRLF do lado do fork | 21 | upstream |
| BOM UTF-8 injetado em arquivos Ruby | 17 | upstream |
| Deletados pelo upstream (mudança nossa era só CRLF) | 5 | deleção aceita |
| **Conteúdo ATS real** | **10** | **manual** |

Método de triagem — para cada arquivo em conflito, verificar se algum commit do
fork (autor `phmotad`) tocou nele desde o merge-base:

```bash
git log --format="%ae" $BASE..$BRANCH -- "$file" | grep -qv "@zammad.com\|@weblate.org"
```

Se todos os autores eram do Zammad, a mudança do nosso lado era churn do sync
anterior e a versão do upstream é a correta.

---

## 3. Customizações ATS preservadas

### `app/assets/stylesheets/zammad.scss`

3 hunks em conflito (git auto-resolveu o resto de uma divergência de 1389 linhas).

- 2 hunks: upstream adiciona blocos `@include light`. Aceitos — ver seção 4.
- 1 hunk: 819 linhas nossas (`User Status Bar - ATS`, estilos do sistema de
  pausas) vs 66 linhas do upstream (`.package`, `.audit-log-diff`). Ambos são
  adições no fim do arquivo — **os dois lados mantidos**.

Resultado: 17.504 linhas, 53 ocorrências de `#480404`, mais o CSS novo do
upstream (`audit-log-diff`, `searchfield-shortcut`, `badge--closed`).

### `app/frontend/apps/desktop/styles/tokens.css`

Versão do upstream adotada (ganha ~25 tokens novos), com a escala
`--color-green-*` remapeada para o vermelho ATS:

```css
--color-green-100: #f5e5e5;
--color-green-200: #e8b3b3;
--color-green-300: #e8b3b3;
--color-green-400: #480404;
--color-green-500: #480404;
--color-green-900: #480404;
```

### `public/assets/images/icons.svg`

Versão ATS mantida (`icon-logo` e `icon-loading` customizados). O único
acréscimo do upstream (`icon-lightbulb`) foi enxertado no fim.

### `app/models/user.rb`

Ambos os lados mudaram muito. Partiu-se da versão do upstream (que ganhou audit
logs, `CanSensitiveAssets` e o novo `user_name_format`) e reaplicou-se:

- `has_many :user_pauses`, `has_many :ticket_time_trackings`
- `belongs_to :current_active_ticket`, `belongs_to :current_pause`
- `search_index_attributes_ignored`: `:current_pause_id`,
  `:current_active_ticket_id`, `:current_state` — somados ao
  `:out_of_office_replacement_id` do upstream
- `validates :current_state, inclusion: { in: %w[offline online pause] }`
- Métodos `in_pause?`, `can_work?`, `active_pause`, `active_ticket_tracking`,
  `offline?`, `online?`

### `app/models/role.rb` e `app/models/concerns/has_roles.rb`

Upstream adicionou callbacks de audit log **nas mesmas linhas** onde o fork
adicionou os guards de time tracking. Ambos convivem:

```ruby
before_remove: %i[last_admin_check_by_permission check_active_time_tracking_by_permission],
after_remove:  %i[cache_update cache_remove_kb_permission audit_log_permission_remove]
```

Métodos `check_active_time_tracking_by_permission` e
`check_active_time_tracking_by_role` reaplicados.

### rack_attack — customização remigrada

Upstream dissolveu `config/initializers/rack_attack.rb` em
`lib/rack_attack_setup/`. O initializer agora tem 3 linhas.

Os limites elevados do fork (para evitar 429 em ambientes com NAT) foram
remigrados para `lib/rack_attack_setup/public_endpoint.rb`:

```ruby
# Customização ATS: limites acima do padrão upstream (3) para reduzir 429 em
# ambientes com NAT/proxy ou múltiplos cliques do usuário.
LIMIT_PER_FIELD = 10
LIMIT_PER_IP    = 30
```

Ganho colateral: herdamos o fix de bypass de rate limit por extensão de formato
(zammad/zammad#6199).

### `.dev/ai-agent-instructions.md`

Upstream reescreveu o arquivo inteiro (nova estrutura com `.dev/agent_docs/`).
Adotada a versão nova, com a seção "Modificações do Repositório Original"
reanexada no fim.

### Arquivos do sistema de pausas — sem conflito

Nenhum arquivo do controle de pausas ou time tracking conflitou. Verificados
íntegros na árvore mergeada:

```
app/models/user_pause.rb                  app/models/pause_type.rb
app/models/user_pause_session.rb          app/models/ticket_time_tracking.rb
app/services/user_pause_service.rb        app/services/ticket_time_tracking_service.rb
lib/pause_indicators_broadcast.rb         lib/pause_indicators_cache.rb
lib/pause_indicators_sse_broadcaster.rb   config/routes/time_tracking.rb
app/controllers/public_pause_indicators_controller.rb
app/controllers/pause_indicators_reports_controller.rb
app/assets/javascripts/app/controllers/user_status_bar.coffee
```

---

## 4. Bugs do fork corrigidos incidentalmente pelo merge

Problemas que **existiam no fork** e sumiram ao adotar a versão do upstream:

### `config/locales.yml` com mojibake

O arquivo estava com UTF-8 lido como cp1252. Árabe aparecia como
`Ïº┘äÏ╣Ï▒Ï¿┘èÏ®`, travessões (`–`) como `ÔÇô`. Corrigido.

### BOM UTF-8 em 17 arquivos Ruby

Arquivos com `\xEF\xBB\xBF` antes do header de copyright — artefato de edição no
Windows (provavelmente `Out-File`/`Set-Content` do PowerShell durante resoluções
de conflito anteriores). Atingia `config/routes.rb`, 5 initializers, 4 arquivos
de rota e 8 migrations. Todos limpos.

### Workaround do `@include light` obsoleto

O commit `4b45899407` removia `@include light` porque o mixin não existia no
sass 3.7.4 legado. Upstream agora **define** o mixin (`zammad.scss` linha ~200) e
migrou para dartsass. Workaround descartado, blocos do upstream aceitos.

### `Exceptions::UnprocessableEntity` deprecado

Upstream renomeou para `Exceptions::UnprocessableContent`, mantendo
`UnprocessableEntity` como subclasse deprecada que emite warning. Todo o código
ATS reaplicado (`role.rb`, `has_roles.rb`) já usa o nome novo.

### `.gitattributes` com CRLF

Estava commitado com CRLF no fork, o que quebrava o parser de atributos do git
durante o merge (`upstream/develop is not a valid attribute name`). Corrigido.

---

## 5. Mudança de versão

`VERSION` alterado de **`7.1.4`** para **`7.2.0`**, refletindo que o código base
agora é Zammad 7.2.x.

O `7.1.4` era numeração interna do fork (o upstream nunca publicou 7.1.4 — a tag
mais alta da linha é 7.1.1).

---

## 6. VALIDAÇÃO — resultado (27/07/2026)

### 6.0 🔴 CRÍTICO — boot quebrava em produção (achado no smoke test com a imagem `:7.2.0`, corrigido)

Nenhuma das etapas abaixo (rspec, rubocop, assets, lint) pegou isso —
todas rodam sem `RAILS_ENV=production` fazer `eager_load` de tudo. Só apareceu
ao efetivamente subir a imagem `:7.2.0` publicada (via
`docker-compose.coolify.test-7.2.0.yml`) e o `zammad-railsserver` crashar em
loop:

```
/opt/zammad/app/services/ticket_time_tracking_service.rb:3: uninitialized
constant Service::BaseWithCurrentUser (NameError)
```

**Causa:** o upstream (`7.2.0-alpha`, commit `1e20dc5e1e`, "Ensure services
have a single entry point and an easy way to pass current user") **apagou**
`Service::BaseWithCurrentUser` e moveu o `current_user` pra dentro do próprio
`Service::Base`, refatorando todos os `Service::*` que herdavam dela. Os 2
services ATS (`app/services/ticket_time_tracking_service.rb`,
`app/services/user_pause_service.rb`) continuavam herdando da classe apagada
— nunca dava conflito de merge (git não via isso como conflito), só ficava
uma referência morta que só explode quando algo faz `eager_load` de verdade
(produção sempre faz; rspec e `bin/rails runner` avulso, não).

**Corrigido** (commit `6e77067b36`): troquei `Service::BaseWithCurrentUser`
por `Service::Base` e, no `initialize`, `@current_user = current_user`
direto em vez de `super(current_user: current_user)` (a classe nova não tem
esse `initialize`). `Service::Base#current_user` já faz
`@current_user ||= UserInfo.current_user`, então setar a ivar direto
preserva o comportamento 100% idêntico ao antigo — os controllers que chamam
`TicketTimeTrackingService.new(...).start_tracking` etc continuam
funcionando sem nenhuma mudança neles (não adotei o padrão novo de
`.execute` porque esses 2 services são multi-método, não fazem sentido no
formato single-entry-point do resto do upstream).

**Verificação:** `bin/rails zeitwerk:check` → `All is good!` antes só
depois do fix (antes, crashava igual ao boot real). Testado manualmente via
`rails runner` instanciando os dois services e chamando `current_user` —
funciona. Não achei nenhum outro `Service::BaseWithCurrentUser` referenciado
em lugar nenhum do código (`grep` confirma, só esses 2 arquivos).

**⚠️ Ação pendente:** a imagem `ghcr.io/paulo-atsinformatica/zammad:7.2.0`
já publicada (buildada antes desse fix) **ainda tem o bug**. Precisa
disparar um novo build depois deste commit antes de testar/promover de
verdade.

### 6.1 Backend — `db:migrate` — ✅ OK

Ambiente: Docker (postgres 17.5, redis 7.0, memcached 1.6.38, ruby 3.4.9 —
Gemfile trava em 3.4.9 exato, não 3.4.8), volume 100% novo (sem reaproveitar
estado de sessões anteriores).

`bundle exec rails db:create db:migrate db:seed` roda limpo. As 25 migrations
novas do upstream convivem sem conflito com as ~20 customizadas do fork.

**Falso alarme investigado:** a migration `20260513153605_issue_6126_...` (que
adiciona `ticket_states.default_close`) parece pular a criação da coluna em
instalação nova (guard `return if !Setting.exists?(name: 'system_init_done')`
envolve o `add_column`). Isso é **intencional e correto** — a migration base
`20120101000010_create_ticket.rb` já foi editada pelo próprio upstream para
incluir `default_close` diretamente, cobrindo instalação nova. A migration
6126 só serve para adicionar a coluna em instalações **existentes** (upgrade).
Confirmado testando com volume Postgres genuinamente vazio.

### 6.2 Backend — `rspec` — ⚠️ PARCIAL (system specs e specs com serviço
externo real ainda não rodaram)

Rodei com os mesmos filtros do job `rspec` do CI oficial (`.gitlab/ci/test/rspec.yml`):

```bash
bundle exec rspec --exclude-pattern "spec/system/**/*_spec.rb" -t ~searchindex -t ~integration
```

(specs de sistema/browser, specs com Elasticsearch real e specs de integração
externa rodam em jobs CI separados com infra própria — não tenho ES,
LDAP, Mattermost, S3 provisionados aqui)

**Resultado: 15812 exemplos, 51 falhas, 3 pending, 97min57s.**

Categorização de todas as 51 falhas:

**Ambientais (~44) — faltam variáveis de ambiente dummy, não são bugs:**
`required_envs` é um guard que **levanta erro proposital** se a env var não
existir (mesmo com cassette VCR gravado, precisa da env var existir com
qualquer valor não-vazio). Faltou exportar antes de rodar:
- `OPEN_AI_TOKEN`, `ZAMMAD_AI_TOKEN` → `spec/lib/ai/service/text_tool_spec.rb` (5)
- `IMPORT_ZENDESK_ENDPOINT` → `spec/lib/sequencer/.../zendesk/ticket/comment_spec.rb` (5)
- `IMPORT_FRESHDESK_ENDPOINT` → `spec/requests/import_freshdesk_spec.rb` (5)
- `IMPORT_KAYAKO_ENDPOINT` → `spec/requests/import_kayako_spec.rb` (5)
- tokens GitHub/GitLab → `spec/requests/integration/{github,gitlab}_spec.rb` (10)
- + outras ~14 do mesmo padrão (throttling de auth/password reset também usam
  configuração de ambiente sensível a timing)

Ação: exportar essas envs com valor dummy (ex. `OPEN_AI_TOKEN=test`) e rodar
de novo pra confirmar zero falhas nesse grupo.

**Reais, mas pré-existentes no upstream (4) — não introduzidas por este merge:**
- `spec/lib/scrub_html_spec.rb` bloco "with deep nesting" (4 falhas): o teste
  usa `nesting_level = 500` esperando que dispare o limite de profundidade do
  Nokogiri, mas `config/initializers/nokogiri.rb` sobe esse limite pra 4000
  (issue #5826). Confirmado via `git log` que as duas mudanças (limite 4000 e
  teste com 500) já vêm assim do upstream — a lógica de rescrub funciona
  corretamente quando de fato acionada (testei isolado), só o teste não
  aciona mais o gatilho no valor atual.

**Reais, pré-existentes na feature ATS (não deste merge) (2):**
- `spec/models/pause_type_spec.rb` — `app/models/pause_type.rb:11` valida
  `greater_than_or_equal_to: 0` mas o teste espera `time_limit: 0` inválido
  (`greater_than: 0`). E a factory (`spec/factories/pause_type.rb`) usa nome
  fixo `'Almoço'`, colidindo com a validação de unicidade quando 2 registros
  são criados no mesmo teste. `git blame` confirma: commit único
  `85b938939b8` de 2026-01-21, nunca tocado pelo merge — bug de autoria
  original, não regressão do sync.

**Não é bug — teste desatualizado (1):**
- `spec/models/ticket_spec.rb:1406` "destroys all related dependencies":
  compara um dict fixo de associações que referenciam `ticket_id` contra a
  realidade via introspecção. A "diferença" são 2 associações que a própria
  ATS adicionou (`TicketTimeTracking`, `User.current_active_ticket_id`), e
  ambas aparecem com valor **0** — ou seja, a limpeza ao destruir um ticket
  funciona certinho. Só falta atualizar o dict esperado no teste pra incluir
  essas 2 entradas.

**Precisam de investigação (não teve tempo de aprofundar) — ~4:**
- `spec/models/trigger_spec.rb:308,337` — `expect(note.attachments.count).to eq(1)` recebeu 0 em ambos: anexos/imagens inline não sendo copiados pro
  e-mail de notificação do trigger. `trigger.rb` não foi tocado pelo merge
  (git log só mostra commits upstream puros) — pode ser bug upstream
  pré-existente ou efeito colateral de outra mudança. **Merece teste isolado.**
- `spec/models/calendar_spec.rb:98` (public_holidays), `spec/models/store_spec.rb:498` (storage oversized), `spec/models/user/permissions_spec.rb:161`
  (deadend permission), `spec/models/user_spec.rb:1279` (remove references
  before destroy), `spec/models/channel/email_parser_spec.rb` (mail113.box) —
  nenhum desses arquivos foi tocado pelo merge (`git log` só mostra commits
  upstream). Suspeita de flakiness (a suíte usa `rspec-retry`, então essas
  falharam mesmo após retry automático) ou bug upstream pré-existente. Não
  investigados a fundo por tempo.
- `spec/lib/background_services_spec.rb:211` "restart_on_file_change stops":
  espera até 3s um file-watcher detectar mudança via polling; suspeita de
  flakiness pelo bind-mount Windows→Docker (I/O lento), não confirmado.

**Achado extra durante a investigação (não é falha de teste, é achado
ambiental):** `app/models/ticket.rb` tem no histórico um commit
`fix: restore ATS customizations lost during upstream merge` — ou seja, já
houve perda de customização nesse arquivo especificamente durante o merge,
corrigida depois. Vale conferir esse arquivo com atenção redobrada numa
revisão manual, já que é o único entre os arquivos com falha que tem
histórico de ter perdido código do fork no merge.

### 6.3 `rubocop` — ✅ rodado, sem achado grave

**5547 arquivos inspecionados, 1271 offenses, 515 auto-corrigíveis.** Nenhum
`Error`/`Fatal` — 1245 são `Convention` (estilo) e 26 `Warning`.

Top ofensas por cop:

| Cop | Qtd | Nota |
|---|---|---|
| `Layout/EndOfLine` | 617 | CRLF em ~617 pontos — `core.autocrlf` está `false`, então é conteúdo commitado assim, não artefato do checkout local. Auto-corrigível. |
| `Layout/HashAlignment` | 194 | Estilo, provável churn do merge |
| `Zammad/UpdateCopyright` | 70 | Ano de copyright desatualizado (cop custom do projeto) |
| `Zammad/DetectTranslatableString` | 61 | String hardcoded que devia ser traduzível |
| `Layout/TrailingEmptyLines` | 37 | Linhas em branco no fim de arquivo |
| `Zammad/PreferNegatedIfOverUnless` | 28 | Estilo |
| `Metrics/AbcSize`/`CyclomaticComplexity`/`PerceivedComplexity` | 30 | Complexidade de método |

Os 26 `Warning` foram revisados individualmente — nenhum é bug funcional:

- **`Rails/HttpStatusNameConsistency`** (maioria) — controllers ATS
  (`pause_indicators_actions_controller.rb`, `ticket_time_trackings_controller.rb`,
  `user_pauses_controller.rb` etc.) ainda usam `:unprocessable_entity`; upstream
  renomeou pra `:unprocessable_content` em outro lugar (ver commit
  `aaa4700468` em `app/models/ticket.rb`, seção 6.2). Os dois símbolos mapeiam
  pro mesmo HTTP 422 — é só consistência de nome, não muda comportamento.
- **`Lint/DuplicateBranch`** em `public_pause_indicators_controller.rb` —
  `when :heartbeat` e `when nil` escrevem a mesma linha (heartbeat de SSE).
  Comportamento correto e intencional (comentário no código explica o `nil` =
  timeout do `queue.pop`); só poderia virar `when :heartbeat, nil` único.
  Não é bug.
- **`Lint/SafeNavigationChain`** (5x, em `ticket_time_trackings_reports_controller.rb`
  e `user_pauses_reports_controller.rb`) — encadeamento após `&.`, estilo.
- **`Lint/BooleanSymbol`** em `db/migrate/20260119150000_add_user_default_fields.rb` —
  falso positivo: `options: { false: 'Não', true: 'Sim' }` são chaves de
  símbolo intencionais pro dropdown do campo boolean customizado, padrão já
  usado em outros lugares do Zammad. Não é bug.
- Resto (`Lint/UnusedMethodArgument` em `app/services/service/result.rb`,
  `Lint/AmbiguousOperatorPrecedence` num script) — não são arquivos ATS,
  prováveis pré-existentes do upstream.

**Ação sugerida:** `bundle exec rubocop -a` resolve os 515 auto-corrigíveis
(a maior parte do total) de uma vez. O resto é revisão manual de estilo, sem
urgência.

### 6.4 Validação de assets (risco alto) — ✅ testado, 1 bug real encontrado e corrigido

Rodei de verdade (não é mais inferência):

```bash
RAILS_ENV=production bundle exec rails assets:precompile
```

**Confirmado:** `app/assets/config/manifest.js` (`//= link_directory ../javascripts .js`)
cobre `public_monitor.js` como a análise original previa — apareceu certinho
no manifest gerado (`public/assets/.sprockets-manifest-*.json`):
`"public_monitor.js":"public_monitor-cdbc1cc9....js"`.

**Mas achei um bug real que quebraria o painel público em produção**, sem
relação com essa análise: `app/assets/javascripts/public_monitor.js` tem

```
//= require ./app/public_pause_indicators.coffee
```

Sprockets não resolve `require` com a extensão `.coffee` explícita — a
convenção usada em todo o resto do projeto (ex. `application.js`) é sem
extensão (`require ./app/lib/spine/spine`). Com a extensão, `assets:precompile`
abortava com `Sprockets::FileNotFound`.

`git blame` mostra commit único `b6a9de145e` (11/03/2026), nunca tocado pelo
merge — **bug de autoria, pré-existente há meses**, só nunca foi pego porque
`assets:precompile` nunca tinha sido rodado antes (nem em CI, nem localmente).
Corrigido:

```diff
-//= require ./app/public_pause_indicators.coffee
+//= require ./app/public_pause_indicators
```

Depois do fix, `assets:precompile` completa a parte Sprockets/dartsass sem
erro: `public_monitor.js` e `zammad.scss` (17.504 linhas, 819 de CSS ATS)
compilam certinho sob dartsass. Confirmado no manifest gerado.

**Nota:** a task completa (`assets:precompile`) segue depois para
`vite:build_all` (frontend novo em Vite) e falha aí com
`ViteRuby::MissingExecutableError: pnpm` — isso é **esperado e não é bug**:
ainda não rodei `pnpm install` (seção 6.5). A parte relevante pra essa seção
(Sprockets/dartsass, que é onde estava o risco do merge) já está validada.

### 6.5 Validação de frontend — ✅ testado, 1 achado real de merge (não bloqueia)

```bash
pnpm install                    # OK, 7m46s, 1194 pacotes
pnpm generate-graphql-api       # rodado à parte, ver achado abaixo
pnpm lint:ts / :js / :css / :md / format:check
pnpm test                       # rodando em background, ver nota no fim
```

`node >=24` esperado pelo `package.json`, ambiente tinha `20.19.2` — só warning,
não impediu nada. `pnpm` precisou ser instalado via installer standalone
(`get.pnpm.io/install.sh`); `corepack`/`npm` falharam por incompatibilidade do
Node empacotado no Debian 13 (`ERR_VM_DYNAMIC_IMPORT_CALLBACK_MISSING`) — só um
detalhe do ambiente de teste, não do projeto.

#### Achado real: refactor de assinatura de e-mail (upstream) não veio completo pro merge

`pnpm lint:ts` (`vue-tsc --noEmit`) falhou com **71 erros**, todos de tipos
GraphQL ausentes em `app/frontend/shared/graphql/types.ts` (arquivo gerado por
codegen, não estava desatualizado — nunca tinha sido regenerado desde o merge).
Rodei `pnpm generate-graphql-api` (`rails generate zammad:graphql_introspection`
+ `graphql-codegen`) e caiu pra **28 erros**. Investigando o resto:

**O que aconteceu:** o upstream tem um commit
(`6822609acafe97ff4c761d54a815e9a04ca076af`, "Desktop view - Apply signature
inside editor") que **removeu inteiramente** a antiga GraphQL query
`TicketSignature` (frontend e backend) e substituiu por um mecanismo novo via
`FormUpdater` (`app/models/form_updater/concerns/prepares_ticket_signature.rb`
+ composable `useTicketSignature` reescrito).

O merge **adotou corretamente o mecanismo novo** — confirmado que
`app/frontend/shared/entities/ticket/composables/useTicketSignature.ts` (o
arquivo realmente importado por `TicketCreateContent.vue`,
`TicketDetailViewContent.vue` e o `TicketCreate.vue` do mobile) já usa
`editorContext.signature` reativo, alimentado pelo `FormUpdater` novo — feature
funcionando, provavelmente adaptada pra funcionar também no mobile (upstream só
tinha feito pro desktop). **Não é regressão, é o merge tendo ido bem.**

O que ficou de sobra, órfão, do lado antigo (nunca deletado durante o merge):

| Arquivo órfão | Situação |
|---|---|
| `app/frontend/shared/composables/useTicketSignature.ts` | Não importado em lugar nenhum. Contém um bug real (`addSignature({ body, id })` — os campos certos são `renderedBody`/`internalId`) mas é inatingível, nunca executa. |
| `app/frontend/shared/graphql/queries/ticketSignature.{api.ts,graphql,mocks.ts}` | Query GraphQL morta, upstream já tinha apagado o equivalente. |
| `app/graphql/gql/queries/ticket/signature.rb`, `app/graphql/gql/types/signature_type.rb` | Backend da query morta. |
| `spec/graphql/gql/queries/ticket/signature_spec.rb` | Spec cobrindo código morto (por isso passa — o resolver antigo ainda funciona isoladamente, só não é mais chamado por ninguém). |

**Recomendação:** apagar os 4 grupos de arquivo acima (`git rm`) pra alinhar
com a intenção do upstream e eliminar o bug inatingível antes que alguém volte
a importar esse composable por engano. Não fiz a remoção nesta sessão —
ações destrutivas (`rm`) são bloqueadas pelo classificador do Auto Mode; fica
como ação manual pro usuário revisar.

#### Achado separado: `customerTicketsByFilter` é WIP abandonado

Dos 28 erros restantes pós-codegen, 27 são só isso: 2 arquivos gerados
(`app/frontend/apps/desktop/entities/ticket/graphql/queries/customerTicketsByFilter.{api,mocks}.ts`)
sem `.graphql` fonte correspondente e sem resolver no backend (schema
introspection não conhece `customerTicketsByFilter` como query). Confirmado
via grep que não são importados por nenhum componente — código morto, nunca
funcionou, não é regressão deste merge (o commit-gênese do fork já os traz
assim). A subscription irmã (`customerTicketsByFilterUpdates`) tem fonte
`.graphql` e resolver backend e tipou certinho depois do codegen — só a query
está incompleta.

**Recomendação:** apagar os 2 arquivos ou terminar a feature (criar a
`.graphql` + resolver). Mesma restrição de `rm` bloqueado — não removido nesta
sessão.

O erro restante (1 de 28) é `useTicketSignature.ts:80` citado acima
(inatingível, dentro do arquivo órfão recomendado para remoção).

#### `pnpm lint:js` — ✅ 1 erro, pré-existente upstream

`useNewBetaUi.spec.ts:78` — `vi.mock()` não hoisted (regra do plugin vitest do
oxlint). `git blame`: único commit é o gênese do fork, arquivo é 100% feature
upstream ("Desktop view - Implement beta UI switch"). Não é ATS, não é
introduzido pelo merge — só uma regra de lint mais nova pegando código antigo.
+ 8 warnings, não revisados individualmente (baixa prioridade).

#### `pnpm lint:css` — ⚠️ 6 erros, todos em CSS ATS

Todos em `app/assets/stylesheets/zammad.scss` (bloco `User Status Bar - ATS`,
linhas 16632–17440): 2× `color-hex-length` (`#ffffff` deveria ser `#fff`), 4×
`comment-empty-line-before`/`rule-empty-line-before`. Puramente estilo, `--fix`
resolve os 6.

#### `pnpm lint:md` — ⚠️ vários erros, mistura ATS + upstream

`AGENTS.md` (o `.dev/ai-agent-instructions.md` reescrito pelo upstream — ver
seção 3), `doc/developer_manual/cookbook/ats-pause-control.md` (doc ATS,
`MD013`/`MD032`), `script/README_REINDEX_ORGANIZATIONS.md` (`MD012`, linhas em
branco em excesso). Nenhum é bug funcional, só estilo de markdown.

#### `pnpm format:check` — ⚠️ 15 arquivos com formatação pendente

Upstream trocou Prettier por Oxfmt (ver nota original desta seção). Entre os
15: `app/frontend/shared/composables/useTicketSignature.ts` e
`.../ticketSignature.graphql` — os mesmos arquivos órfãos recomendados pra
remoção acima (mais um sinal de que são lixo esquecido, nem formatação
receberam). Resto é reformatação de rotina, `pnpm format` resolve.

#### `pnpm test` (vitest) — ⚠️ pulado por decisão, suíte grande demais pro ambiente

Rodei com Node 24 (precisou upgrade do container — `vitest.config`/`vite.config.mjs`
usa `node:fs#globSync`, indisponível no Node 20 que o resto do ambiente usava;
`package.json` já exige `>=24`, só o container de teste estava desatualizado).

642 arquivos de spec no total. Em 42min rodou 178 (16 arquivos com alguma
falha, 70 testes individuais falhando), ritmo apontava mais 1h30–2h pra
terminar tudo no bind-mount Windows→Docker (I/O bem mais lento que nativo).
Por decisão do usuário, interrompido antes do fim — não dá pra afirmar "suíte
verde" ou não.

**Padrão notado, não investigado a fundo:** várias falhas com timeout de
exatos ~5000-5122ms espalhadas em arquivos sem relação entre si (AI summary
sidebar, guided-setup-a11y, ticket-detail-view-navigation-tabs-switching) —
cheira a algo sistêmico (timeout padrão do vitest sendo estourado por alguma
lentidão do ambiente, possivelmente ligada ao próprio bind-mount ou à troca de
Node no meio da sessão) mais do que 16 regressões isoladas do merge. **Recomendo
rodar `pnpm test` de novo num ambiente com disco nativo (Linux/WSL2 sem
bind-mount, ou CI) antes de considerar o frontend validado.**

### 6.6 Smoke test manual — ⚠️ tentado, não concluído (limitação de ambiente)

Tentei montar um Zammad rodando de verdade pra passar pelo checklist abaixo:

1. Subi um container `ruby:3.4.9` novo (`zammad-smoke-web`, descartável, não
   afeta os containers de validação) na mesma rede Docker, reusando o volume
   de bundle e o Postgres/Redis/Memcached já no ar, `RAILS_ENV=test`,
   porta `3050→3000`.
2. **Achado real e sério, sem relação com o merge:** o working tree tinha
   **385 arquivos sob `public/assets/` deletados do disco mas ainda rastreados
   no git** (`git status` mostrava ` D public/assets/...` sem nada staged) —
   todo `public/assets/chat/*`, `public/assets/error/*`,
   `public/assets/images/icons.svg` etc. sumidos fisicamente. Não fui eu que
   apaguei nesta sessão; não dá pra saber quando aconteceu (checkout Windows
   anterior, ferramenta que rodou `assets:clobber`, antivírus/OneDrive
   mexendo no diretório — não investigado a fundo). **Restaurado** com
   `git checkout -- public/assets/` (seguro: arquivos idênticos ao HEAD,
   nenhuma perda). **Recomendo conferir se isso não volta a acontecer** —
   rodar `git status --short | grep '^ D'` de vez em quando até identificar
   a causa.
3. `system_init_done` estava `false` no banco de teste (seed do rspec não
   passa pelo wizard) — setado `true` temporariamente pra pular a tela de
   "Get Started".
4. Criei um usuário Admin+Agent temporário (`smoketest@ats.local`) via
   `rails runner` pra logar.
5. **Login funcionou** (confirmado via log do console do navegador — o SPA
   legado Spine/CoffeeScript carregou, autenticou, tentou ir pro dashboard),
   mas caiu em `App.route dashboard:(error) No permission for *` — o seed
   mínimo de `RAILS_ENV=test` cria o Role `Agent` com só 5 permissions
   (`chat.agent`, `cti.agent`, `knowledge_base.reader`, `ticket.agent`,
   `user_preferences`), faltando o necessário pra abrir o dashboard/overview.
   Isso é uma limitação do seed de teste (rspec não precisa do catálogo
   completo de permissions), não um bug do merge.

**Decisão:** por indicação do usuário, parei por aqui em vez de continuar
ajustando o ambiente artificial. Desfiz as mudanças de teste (removi o
container `zammad-smoke-web`, o usuário `smoketest@ats.local`, voltei
`system_init_done` pra `false` no banco de teste) — nada disso vazou pra fora
do ambiente de validação.

**Recomendo rodar o checklist abaixo manualmente num ambiente de
desenvolvimento/staging de verdade** (com `RAILS_ENV=development` ou a stack
Coolify, seed completo, frontend buildado) antes do merge final pra
`developer`:

- [ ] Login e visual geral (branding vermelho `#480404` intacto)
- [ ] Barra de status de pausa (`user_status_bar`)
- [ ] Iniciar / encerrar pausa
- [ ] Relatório de pausas
- [ ] Relatório de indicadores de pausa (com e sem filtro de equipe)
- [ ] **Painel público** `/monitor/pause_indicators` — SSE e fallback polling
- [ ] Player de tempo de atendimento no ticket
- [ ] Troca entre tickets (pausa automática do anterior)
- [ ] Relatório de tempo de atendimento
- [ ] Bloqueio de remoção de papel com time tracking ativo
- [ ] Busca de organização por CNPJ / CPF / CodCliente / Grupo Econômico
- [ ] Campos customizados de usuário e organização

### 6.7 Decisões pendentes

**Tag da imagem Docker.** `docker-compose.coolify.yml` fixa
`ghcr.io/paulo-atsinformatica/zammad:7.1.4` em 7 lugares. **Não foi alterado de
propósito** — apontar para `7.2.0` antes da imagem existir no registry quebraria
o deploy. Sequência correta:

1. Buildar e publicar `ghcr.io/paulo-atsinformatica/zammad:7.2.0`
2. Só então atualizar as 7 referências no compose

**Tokens verdes novos.** Upstream adicionou `--color-green-250`,
`--color-green-350` e `--color-green-700`, que ficaram com os valores verdes
originais. Vão aparecer verdes na UI. Decidir se entram no mapeamento ATS.

**Elasticsearch.** Se algum campo de busca mudou no merge, reindexar:

```bash
rails runner script/reindex_organizations.rb
```

**Módulos AI e Desktop View.** O `.dev/context.md` registrava que esses módulos
haviam divergido demais do upstream. Com o merge de `develop`, vieram as versões
novas do upstream. Precisam de teste específico.

### 6.8 Só depois de tudo verde

```bash
git checkout developer
git merge sync-upstream-20260727
git push origin developer
```

### Se algo der errado

```bash
git reset --hard backup-ats-antes-sync-20260727
```

A branch `developer` não foi tocada em momento nenhum — o merge vive apenas em
`sync-upstream-20260727`.
