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

## 6. PENDÊNCIAS — nada disso foi validado

> **O merge não foi testado.** Nenhum comando de build, migração ou teste foi
> executado sobre o resultado do merge. Tudo abaixo é obrigatório antes de
> qualquer push ou deploy.

### 6.1 Validação de backend (obrigatório)

```bash
bundle exec rails db:migrate
```

O merge trouxe **25 migrations novas** do upstream. Precisam rodar limpo, e
precisam conviver com as ~20 migrations customizadas do fork
(`20251224*` a `20260518*`).

```bash
bundle exec rspec
```

Rodar a suíte inteira. Atenção especial a:

- `spec/models/user_spec.rb` — `user.rb` foi mergeado manualmente
- `spec/models/role_spec.rb` — `role.rb` foi mergeado manualmente
- `spec/requests/settings_spec.rb` — contém os 2 examples novos do fix de 404
- `spec/models/pause_type_spec.rb`, `user_pause_spec.rb`,
  `ticket_time_tracking_spec.rb` — specs do sistema de pausas
- `spec/lib/pause_indicators_sse_broadcaster_spec.rb`

```bash
bundle exec rubocop
```

### 6.2 Validação de assets (risco alto)

Upstream migrou o pipeline para **dartsass-rails**.
`config/initializers/assets.rb` foi adotado do upstream — todas as linhas
`Rails.application.config.assets.precompile +=` sumiram.

A linha ATS `precompile += %w[public_monitor.js]` foi descartada por análise: o
novo `app/assets/config/manifest.js` tem `//= link_directory ../javascripts .js`,
que deve cobrir `app/assets/javascripts/public_monitor.js`.

**Isso é uma inferência de leitura de código, não foi testado.** Validar com:

```bash
RAILS_ENV=production bundle exec rails assets:precompile
```

E depois confirmar que `/monitor/pause_indicators` carrega o JS. O layout
`app/views/layouts/public_monitor.html.erb` faz
`javascript_include_tag "public_monitor"` — se o asset não for precompilado, o
painel público quebra em produção.

Verificar também se `zammad.scss` compila sob dartsass — o arquivo tem 17.504
linhas com 819 linhas de CSS ATS que nunca passaram por esse compilador.

### 6.3 Validação de frontend

```bash
pnpm install
pnpm lint
pnpm test
```

`pnpm-lock.yaml` e `package.json` vieram do upstream. Upstream trocou Prettier
por **Oxfmt** — pode haver reformatação em massa pendente.

### 6.4 Smoke test manual

Depois do build, testar na aplicação:

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

### 6.5 Decisões pendentes

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

### 6.6 Só depois de tudo verde

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
