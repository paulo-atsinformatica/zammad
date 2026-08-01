# Pendências ATS

Pontos levantados em produção/teste. Cada item registra o sintoma, o que se sabe e
as pistas, para a investigação não recomeçar do zero.

Ao resolver e **validar** um item, mover para `custom-branding-ats-modifications.md`
com a explicação do porquê, e remover daqui.

## Estado em 01/08/2026

| Item | Estado |
|---|---|
| 1. Aviso de BETA no relatório | implementado, não validado |
| 2. Seletor "Relatório" vazio | provavelmente resolvido pelo item 6 (ver nota) |
| 3. Redimensionar/ordenar colunas | implementado, não validado |
| 4. Paginação | nada a fazer, só registro |
| 5. Formato de exportação no clique | implementado, não validado |
| 6. Compartilhar por grupos e usuários | implementado, não validado |
| 7. Contagem após troca de proprietário | implementado, não validado |
| 8. Tempo por atendente | backend implementado; **falta a exibição** |
| 9. Visual do player e contraste | implementado, não validado |
| 10–15 (auditoria) | 10, 11, 13 implementados junto do 16; 12 e 14 em aberto |
| 16. Pausado bloqueia iniciar outro | implementado, não validado |

**"Não validado" é literal:** o Docker local parou de responder no meio do
trabalho, então nada aqui passou por rspec, rubocop, `lint:ts` ou build. É a
primeira coisa a fazer quando o ambiente voltar.

Ainda em aberto, além da validação:

- **Item 8** — o endpoint `GET /tickets/:id/time_tracking/summary` existe e
  devolve o tempo por atendente, mas nenhuma tela consome.
- **Item 12** — contagem esquecida correndo indefinidamente.
- **Item 14** — verificar se `type: 'authenticated'` alcança clientes.
- **Item 15** — specs dos cenários corrigidos.

---

## 1. Aviso de BETA aparece na tela de relatório personalizado

**Sintoma**

> Nova interface BETA para desktop
> Esta nova interface BETA para desktop está atualmente em desenvolvimento e não
> está pronta para uso em produção. Pode conter erros ou recursos incompletos.

O aviso aparece ao abrir `/report/custom-reports`. Não deveria: a tela de
relatório não é a Desktop View, apenas reaproveita o mesmo bundle.

**O que já se sabe**

O aviso é disparado no nível do app, não da rota. Em
`app/frontend/apps/desktop/AppDesktop.vue`:

```
const { switchValue } = useBetaUi()
initializeBetaUiFeedbackConsentDialog()

if (switchValue.value) {
  useBetaUiFeedbackConsent()
  useBetaUiFeedbackRouteGuard()
} else {
  useBetaUiDisclaimer()
}
```

Como `AppDesktop.vue` é a raiz do bundle, isso roda em **qualquer** página servida
por ele — incluindo `/report/*`, que a customização ATS passou a servir com o
mesmo bundle (ver `config/routes/custom_report_ui.rb` e a base de history em
`app/frontend/apps/desktop/router/index.ts`).

**Pistas para a correção**

- O ponto de montagem já é conhecido em tempo de execução (a mesma lógica que
  define a base do history distingue `desktop` de `report`). Dá para condicionar
  o disclaimer a isso.
- `AppDesktop.vue` é arquivo do upstream: qualquer mudança ali entra na lista de
  arquivos tocados em `custom-branding-ats-modifications.md`.
- Verificar também `useBetaUiFeedbackRouteGuard`, que provavelmente tem o mesmo
  problema para quem já aderiu ao BETA.

---

## 2. Seletor "Relatório" vem vazio na tela de visualização

**Sintoma**

Na tela `/report/custom-reports`, o campo **Relatório** abre o dropdown e mostra
"Nenhum resultado encontrado" — nenhuma opção listada.

O detalhe que torna o caso estranho: **o grid abaixo mostra dados**. Ou seja,
existe um relatório selecionado e a consulta de resultados está rodando; só a
lista de opções do seletor está vazia.

**O que já se sabe**

- A tela ficou com **dois formulários**: um estático (visibilidade + formato) e um
  dinâmico (só o seletor de relatório), justamente porque um schema `computed`
  é recriado quando muda e o FormKit reaplica o valor inicial de cada campo.
- As opções do seletor vêm de `reports.value.map(...)`, que sai da query
  `customReportList`.
- O filtro de visibilidade estava em "Todos", que manda `visibility: undefined` —
  o backend trata ausência do argumento como "todos".

**Hipóteses a testar, em ordem**

1. A query `customReportList` está devolvendo erro (aí `reports` fica `[]`) e o
   grid está exibindo dado em cache do Apollo de antes. Confirmar no console do
   navegador se há erro de GraphQL nessa query.
2. O schema dinâmico é reconstruído depois que as opções chegam e o FormKit não
   está reaplicando a lista de opções ao nó já montado.
3. Regressão da mudança de visibilidade: relatórios que eram `global` foram
   convertidos para `group` com todos os grupos por migration; se essa migration
   não rodou nesta instância, os registros ficaram com `visibility: 'global'`,
   que não passa mais na validação nem nos escopos de `CustomReport.visible_to`.
   **Esta é a hipótese mais provável se a instância não rodou as migrations
   novas.** Verificar com:

   ```
   CustomReport.group(:visibility).count
   ```

**Como reproduzir**

Abrir `/report/custom-reports` e clicar no campo Relatório.

---

## 3. Grid do relatório sem redimensionar coluna nem ordenar por clique

**Sintoma**

No grid de `/report/custom-reports` não dá para arrastar a divisa da coluna para
mudar a largura, nem clicar no cabeçalho para ordenar.

**O que já se sabe**

A tela usa `CommonSimpleTable`, que é o componente **simples**: renderiza
cabeçalho e linhas e nada mais. Redimensionamento e ordenação existem no
componente avançado — em `#desktop/components/CommonTable/types.ts`,
`AdvancedTableProps` traz `orderBy`, `orderDirection`, `isSorting`, `onLoadMore`
e `storageKeyId`, e `TableHeaderPreference` traz `displayWidth`, `noResize` e
`noSorting`, além das constantes `MINIMUM_COLUMN_WIDTH` e `MINIMUM_TABLE_WIDTH`.

O backend **já está pronto** para a ordenação: `customReportResults` aceita
`orderBy` e `orderDirection`, e `CustomReport::Query#ordered` só aceita coluna
real da tabela (o valor vem da requisição e iria direto ao `ORDER BY`), caindo
para `id` quando o nome não confere.

**Pistas para a correção**

- Trocar `CommonSimpleTable` por `CommonAdvancedTable` na tela de visualização.
- O componente avançado espera `attributes` descrevendo cada coluna com
  `dataType`, e não apenas `{ key, label }`. O backend hoje devolve
  `{ name, display }` por coluna; provavelmente vale incluir o tipo do atributo
  no metadado de coluna, do mesmo jeito que já é feito para os filtros em
  `CustomReport::FilterDefinition`.
- `storageKeyId` é o que persiste a largura escolhida entre sessões.
- Ligar o clique do cabeçalho a `orderBy`/`orderDirection` e repassar para a
  query, voltando para a página 1 a cada troca de ordenação.

---

## 4. Paginação da tela de relatório — confirmado que existe

Não é defeito, fica registrado para não ser reinvestigado.

A paginação **existe** de ponta a ponta:

- Backend: `CustomReport::Query::DEFAULT_PER_PAGE = 50` e `MAX_PER_PAGE = 200`
  (teto aplicado no servidor); `CustomReport::Result` devolve `page`, `perPage`,
  `totalPages` e `totalCount`.
- Tela: botões Anterior/Próxima e "Página X de Y".

O controle só é renderizado quando `totalPages > 1`, então com 50 linhas ou menos
não aparece nada — foi o que ocorreu no teste.

**A rever junto do item 3:** não há como escolher o tamanho da página pela
interface, e o total de registros aparece só como texto. Se a listagem virar o
componente avançado, avaliar rolagem infinita (`onLoadMore`) no lugar dos botões.

---

## 5. Formato de exportação deve ser perguntado no clique, não ficar na barra

**Sintoma**

O seletor "Formato de exportação" (CSV / Excel) ocupa espaço permanente na barra
superior da tela, mesmo quando o usuário só quer consultar. Ele deveria sumir da
barra: ao clicar em **Exportar**, abre um diálogo perguntando o formato e só então
enfileira.

**O que já se sabe**

- O seletor hoje faz parte do schema estático da barra em
  `app/frontend/apps/desktop/pages/custom-report/views/CustomReport.vue`
  (campo `format`), e alimenta o ref `format`, lido em `exportReport()`.
- Quem enfileira é `useCustomReportExport().generate(customReportId, format)`, em
  `pages/custom-report/composables/useCustomReportExport.ts`. A assinatura já
  recebe o formato como argumento, então **o backend e o composable não mudam** —
  a mudança é só de onde vem esse valor.
- A Desktop View já tem diálogo pronto para isso: ver
  `initializeConfirmationDialog()` em `AppDesktop.vue` e o
  `DynamicInitializer name="dialog"`. Vale checar
  `#desktop/components/CommonConfirmationDialog` e os utilitários de flyout/dialog
  antes de montar componente novo.

**Pistas para a correção**

- Tirar o campo `format` do `staticSchema` e o ref correspondente da barra.
- No clique de Exportar, abrir o diálogo com as duas opções e passar a escolha
  direto para `generate(...)`.
- Manter `csv` como padrão pré-selecionado no diálogo, que é o formato sem teto de
  linhas (o xlsx falha acima de 1.048.575 por limite do próprio formato — ver
  `CustomReport::Exporter::Xlsx::MAX_ROWS`).
- Se o diálogo virar componente próprio, cuidado com o mesmo problema do item 2:
  schema `computed` remonta o Form e reaplica valores iniciais.

---

## 6. Trocar o modelo de visibilidade por compartilhamento no estilo Visão Geral

**Mudança pedida**

Remover a escolha "Visualização pessoal / Geral". No lugar:

- Na **configuração** do relatório, escolher **grupos** e também **usuários** que
  enxergam o relatório, como já existe na Visão Geral.
- Na **visualização**, filtrar por grupo, ou pelos relatórios **atribuídos
  diretamente a mim**.

**Como a Visão Geral faz (padrão a seguir)**

`app/models/overview.rb`:

```ruby
has_and_belongs_to_many :roles, ..., class_name: 'Role'
has_and_belongs_to_many :users, ..., class_name: 'User'
validates :roles, presence: true
```

`app/assets/javascripts/app/models/overview.coffee`:

```coffee
{ name: 'role_ids', display: __('Available for the following roles'),
  tag: 'column_select', multiple: true, null: false, relation: 'Role', translate: true },
{ name: 'user_ids', display: __('Restrict to only the following users'),
  tag: 'column_select', multiple: true, null: true, relation: 'User', sortBy: 'displayName' },
```

Ou seja: `column_select` com `relation`, componente que **já existe** — é o mesmo
que o relatório personalizado usa hoje em `group_ids`. Não precisa de UI nova.

Repare na semântica da Visão Geral: papéis definem **quem tem acesso**, e usuários
**restringem** dentro disso (o campo se chama "Restrict to only the following
users"). Definir qual das duas semânticas queremos para grupos e usuários antes de
implementar — "união" (vê quem estiver em qualquer das listas) ou "interseção"
(vê quem estiver nas duas) muda o resultado.

**O que muda no que já existe**

- `CustomReport::VISIBILITIES` e `VISIBILITY_PERMISSIONS` deixam de fazer sentido,
  junto com a coluna `visibility` e a permissão `report.custom.group`.
- `CustomReport.visible_to` / `#visible_to?` passam a considerar
  `group_ids` **e** `user_ids`.
- Precisa de `has_and_belongs_to_many :users` e da tabela de junção.
- Migration de conversão dos registros existentes:
  - `visibility: 'personal'` → `user_ids: [created_by_id]`
  - `visibility: 'group'` → mantém `group_ids`, `user_ids` vazio
- Frontend legado (`models/custom_report.coffee`): remover o select de
  visibilidade, acrescentar `user_ids` como `column_select` com
  `relation: 'User'` e `sortBy: 'displayName'`, e incluir `user_ids` no
  `@configure` — atributo fora dessa lista é **descartado em silêncio** pelo
  Spine ao gravar (foi bug real antes, ver item equivalente no doc principal).
- Tela Vue: o seletor "Visível para" passa a oferecer **Todos / Por grupo /
  Atribuídos a mim**. O argumento `visibility` da query `customReportList` some e
  entra algo como `scope` + `groupId`.
- `Gql::Queries::CustomReport::List#restrict` acompanha.
- Specs a refazer: `spec/models/custom_report_spec.rb` (todo o bloco de
  visibilidade), `list_spec.rb`, e a factory `:custom_report_general`.

**Atenção**

Isto **desfaz** a mudança feita em `20260730130000_drop_custom_report_global_visibility.rb`
(que tirou o nível global). Antes de implementar, decidir se a coluna `visibility`
sai de vez ou fica como legado — e escrever a migration de conversão com o mesmo
cuidado: ninguém pode **ganhar** acesso a relatório que não via, nem perder o que
via.

Vale lembrar o invariante que continua valendo em qualquer desenho: isto controla
quem enxerga o **modelo** do relatório. O escopo dos **dados** é sempre recalculado
a partir das permissões de quem gera (`CustomReport::Query`), então compartilhar um
relatório nunca revela registro que a pessoa não veria sozinha.

---

## 7. Contagem continua após troca ou remoção do proprietário — BUG

**Prioridade: alta.** É o único item desta lista que gera **dado errado**, não só
incômodo visual.

**Sintoma**

Com o player rodando, ao transferir o ticket para outro proprietário — ou ao
remover o proprietário — a contagem **continua correndo** para o usuário antigo.
Deveria parar.

**O que já se sabe**

`app/services/ticket_time_tracking_service.rb` valida o proprietário **só na
transição**, nunca depois:

```ruby
return error(__('Ticket is not assigned to user')) if @ticket.owner_id != current_user.id
```

Isso aparece em `start_tracking` (linha ~15), `resume_tracking` (~55) e na
transferência entre tickets (~112). Não há nada observando `Ticket#owner_id`, então
uma contagem já ativa segue viva indefinidamente.

`app/models/ticket_time_tracking.rb` tem `pause_and_deactivate!` e `end!`, que são
exatamente as ações necessárias — falta só o gatilho.

**Pistas para a correção**

- Reagir à mudança de `owner_id` do ticket. Duas rotas possíveis:
  observer/callback no `Ticket` (mas é arquivo do upstream — entra na lista de
  arquivos tocados) ou um job disparado pela alteração.
- Decidir a **semântica**, que é a parte que importa:
  - encerrar (`end!`) e fechar o intervalo, ou
  - pausar (`pause_and_deactivate!`) mantendo o acumulado para retomada.

  Encerrar parece o certo: quem não é mais dono não deve retomar aquilo. Mas isso
  precisa ser decidido antes de codar, junto com o item 8.
- Cuidado com o caminho de **merge** de tickets e com alteração em massa
  (bulk update), que também trocam proprietário.
- Cobrir com spec os três casos: troca de proprietário, remoção do proprietário
  (`owner_id` volta para 1) e merge.

---

## 8. Ver o tempo de cada atendente quando o ticket passa de mão

**Necessidade**

Um atendente inicia o atendimento e repassa para outro. Hoje não há como visualizar
o tempo dos dois lado a lado.

**O que já se sabe**

O modelo **já suporta** isso: `TicketTimeTracking` tem `belongs_to :user` e o
escopo `for_user`, então já existe um registro por usuário por ticket. O dado está
lá; falta exibição.

**Pistas**

- Levantar o que já existe no relatório de Tempo de Atendimento antes de criar
  tela nova.
- Na aba lateral do ticket, mostrar a lista por atendente com o total de cada um,
  além do total geral.
- Ligado ao item 7: a decisão entre `end!` e `pause_and_deactivate!` define se o
  histórico fica com um intervalo fechado por atendente (bom para este relatório)
  ou com um acumulado retomável.

---

## 9. Player do controle de tempo com visual pobre

**Sintoma**

O player na barra inferior do ticket está feio e destoa do resto da interface.

**Estado atual**

Botões play/pause quadrados com o cronômetro em caixa amarela ao lado, à direita
da barra inferior. Na aba lateral, o ticket ativo aparece com o cronômetro em
destaque amarelo.

**Pistas**

- Componente em
  `app/assets/javascripts/app/controllers/ticket_zoom/time_tracking.coffee` e
  `views/ticket_zoom/time_tracking.jst.eco`; o indicador da aba está em
  `controllers/taskbar_time_tracking_indicator.coffee`.
- É SPA legado (CoffeeScript + eco + SCSS), não Vue — o visual precisa sair do
  mesmo vocabulário do resto da tela antiga.
- O amarelo forte destoa da paleta ATS (vermelho `#480404`). Ver o branding em
  `app/assets/stylesheets/zammad.scss`.
- **Na aba lateral o cronômetro fica ilegível** — o contraste entre o texto e o
  fundo amarelo não dá. É acessibilidade, não só gosto: conferir contraste mínimo
  ao escolher a cor nova.
- Puramente cosmético: fazer **depois** do item 7, que corrige dado errado.

---

## Auditoria do controle de tempo — achados não relatados

Levantamento feito lendo `app/services/ticket_time_tracking_service.rb` e
`app/models/ticket_time_tracking.rb`. Nenhum destes foi reportado pelo usuário;
saíram da leitura do código. Ordenados por gravidade.

### 10. `switch_tracking` pode ressuscitar uma contagem já encerrada — BUG

Em `switch_tracking` (linha ~118):

```ruby
paused_tracking = TicketTimeTracking.find_by(ticket: to_ticket, user: current_user, is_active: false)
if paused_tracking.present? && paused_tracking.paused_at.present?
  ... paused_tracking.reactivate!
```

Falta o filtro `ended_at: nil`. E `end!` **não limpa `paused_at`** quando o
registro já estava pausado, então um registro **encerrado** satisfaz
`paused_at.present?` e é reativado — o intervalo fechado volta a correr.

A evidência de que é bug, e não intenção: os outros dois caminhos que procuram
contagem retomável (`resume_tracking` linha ~62 e `current_tracking` linha ~163)
**filtram `ended_at: nil`**. Só o `switch_tracking` não filtra.

### 11. "uma contagem ativa por usuário" não é garantida

Duas falhas independentes no mesmo invariante:

1. A validação `only_one_active_per_user` é `on: :create`. Mas `reactivate!` liga
   `is_active = true` num registro **existente** via `save!` — a validação não
   roda. Hoje o serviço protege esse caminho, mas o modelo não.
2. Não há índice único no banco. Dois requests simultâneos de "iniciar" passam
   os dois pela validação (leitura e escrita não são atômicas) e criam duas
   contagens ativas.

Correção sugerida: índice único parcial em `user_id` com `WHERE is_active`, que
resolve os dois de uma vez, e estender a validação para `on: %i[create update]`.

### 12. Contagem deixada aberta indefinidamente

Nada encerra uma contagem esquecida. Agente inicia, fecha o navegador e vai
embora: `is_active` continua `true` e `total_time_seconds` cresce sem limite,
somando noite e fim de semana. Aparece no relatório como tempo de atendimento.

Não existe duração máxima, encerramento automático nem reconciliação.

Observação: o **controle de pausa** já se integra — `UserPauseService#start_pause`
chama `active_tracking&.pause!` e o fim da pausa oferece retomar. Ou seja, o
padrão de integração já existe; falta o caso "usuário sumiu".

Sugestões a avaliar: teto configurável por contagem, encerramento no logout, e um
job de varredura para contagens ativas há mais de N horas.

### 13. Contagem desativada por troca de ticket nunca pode ser encerrada

`end!` começa com `return false if !active?`, e `active?` exige `is_active`. Já
`pause_and_deactivate!` (usado na troca de ticket) deixa `is_active = false` com
`ended_at: nil`.

Resultado: esses registros ficam num limbo — não dá para encerrar pela interface,
e acumulam por ticket/usuário. `current_tracking` continua exibindo eles.

Definir o que significa "encerrar" para esse estado e permitir a transição.

### 14. Estado de tempo é transmitido para todos os usuários autenticados

`broadcast_state_change` faz:

```ruby
PushMessages.send(message: ticket_message, type: 'authenticated')
```

O payload leva `ticket_id`, `user_id` e o tempo acumulado. Diferente do primeiro
broadcast do mesmo método, que é dirigido (`send_to(user_id, ...)`), este vai para
**todo mundo autenticado**.

**Verificar se clientes recebem.** Se receberem, é vazamento: um cliente passaria a
saber qual atendente está com qual ticket e há quanto tempo. Mesmo entre agentes,
vale limitar a quem tem acesso ao grupo do ticket.

Confirmar o alcance real de `type: 'authenticated'` em `lib/push_messages.rb` antes
de concluir — pode ser que já seja restrito.

### 15. Sem cobertura para os cenários acima

Os specs existentes cobrem o caminho feliz. Faltam: troca/remoção de proprietário
(item 7), reativação de contagem encerrada (item 10), concorrência em "iniciar"
(item 11), o limbo do item 13 e o falso conflito do item 16.

---

## 16. Ticket pausado ainda bloqueia iniciar outro — BUG

**Sintoma**

O usuário **pausa** o ticket A e vai para o ticket B. Ao iniciar a contagem em B,
aparece mesmo assim:

> Outro ticket em atendimento
> Você já está atendendo o ticket #43004. Deseja pausar esse ticket e iniciar a
> contagem neste?

O ticket A já estava pausado — não havia nada para pausar, e a mensagem afirma
algo falso ("você já está atendendo").

**Causa**

`is_active` carrega **dois significados diferentes**, e é aí que o bug nasce:

1. "ocupa o slot único do usuário" (`only_one_active_per_user`)
2. "está correndo agora"

`TicketTimeTracking#pause!` só marca `paused_at` — **mantém `is_active = true`**.
Quem zera a flag é `pause_and_deactivate!`, usado apenas na troca de ticket.

Aí, em `User#active_ticket_tracking` (`app/models/user.rb:1213`):

```ruby
def active_ticket_tracking
  ticket_time_trackings.active.first   # scope :active -> where(is_active: true)
end
```

Uma contagem **pausada** continua sendo devolvida. E `start_tracking` (linha ~18)
usa exatamente isso como guarda:

```ruby
existing_tracking = current_user.active_ticket_tracking
if existing_tracking.present?
  return error(__('User already has an active ticket time tracking'), ...)
```

Logo, pausar não libera o usuário para iniciar outro ticket.

**Pistas para a correção**

- A guarda de conflito deveria olhar "está **correndo**", não "ocupa o slot" —
  isto é, `is_active && !paused?`. Já existe `TicketTimeTracking#paused?`.
- Decidir se um pausado deve continuar segurando o slot único. Se **não** deve,
  `pause!` também zera `is_active` e o desenho fica coerente com `resume_tracking`,
  que já sabe reativar contagem desativada. Se **deve**, então só a guarda muda.
- `pause!` também **não limpa** `User#current_active_ticket_id`, então o indicador
  da aba lateral pode seguir apontando o ticket pausado.
- Separar os dois significados de `is_active` resolveria de uma vez os itens
  **11**, **13** e **16**, que são sintomas da mesma sobrecarga. Vale considerar
  uma coluna de estado (`running` / `paused` / `ended`) em vez de flags soltas —
  `current_state` já deriva isso, mas só para exibição.
- Ao mexer, verificar `switch_tracking`, que depende de `from_tracking` vir do
  escopo `active`.
