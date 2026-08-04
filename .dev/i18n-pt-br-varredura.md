# Varredura i18n – Português do Brasil (pt-BR)

Este documento lista o que ainda precisa de tradução para pt-BR no projeto, com base em uma varredura no código e no arquivo `i18n/zammad.pt-br.po`.

---

## 1. Arquivo principal de tradução: `i18n/zammad.pt-br.po`

### Entradas ainda sem tradução (msgstr vazio)

Há **cerca de 99 entradas** no `zammad.pt-br.po` com `msgstr ""` (além do cabeçalho do arquivo). Ou seja, essas strings existem no catálogo mas ainda não têm tradução em pt-BR.

**Observação:** O Zammad oficial gerencia traduções via [translations.zammad.org](https://translations.zammad.org/). Pull requests que alterem os `.po` diretamente são rejeitados. Para contribuir com pt-BR no upstream, use o Weblate. **Neste fork (ATS):** o arquivo `i18n/zammad.pt-br.po` é mantido igual ao upstream. As customizações (ex.: padronização "ticket" em vez de "Chamado"/"Tíquete", e ajustes de IA) são aplicadas **no banco**, como se feitas pela interface: após `Translation.sync`, o módulo `TranslationOverridesPtBr` (em `lib/translation_overrides_pt_br.rb`) é executado e atualiza as traduções pt-BR. Assim o .po não é alterado e as customizações persistem no banco.

### Exemplos de strings sem tradução (amostra)

| msgid (original) | Categoria / contexto |
|------------------|----------------------|
| "A new version of Zammad is available, please reload your browser." | Avisos / UI |
| "A newer version of the app is available. Please reload at your earliest." | Avisos |
| "AI agent result content does not match expected result structure." | AI / erros |
| "AI assistance text tool is inactive." / "is invalid." | AI |
| "AI provider Ollama URL is not set" | AI / configuração |
| "API server error - please try again" / "API server not accessible" | API / erros |
| "Accessing your camera is forbidden. Please check your settings." | Câmera / permissões |
| "Add SMS" | Canais |
| "Admin password login instructions were sent to your email address." | Login |
| "Agents with \"%s\" permission" | Permissões |
| "Agree & join" | UI |
| "All categories will be considered for categorizing tickets." | Categorias |
| "All computers and browsers from which you logged in to Zammad appear here." | Dispositivos |
| "All two-factor authentication methods were removed for this user." | 2FA |
| "Allow AI Agent to select multiple categories from all possible values." | AI |
| "Allow admins to manage availability and access to the desktop BETA UI switch." | BETA UI |
| "Archive cut-off time" | Arquivo / tempo |
| "Are you sure you want to reload? You have unsaved changes that will get lost" | Confirmação |
| "Are you sure? Your notifications settings will be reset to default." | Notificações |
| "At least one match rule is required, but none was provided." | Regras |
| "Author name and article creation date" | Relatórios / artigos |
| "Auto Shutdown" | Sistema |
| "Azure AI" | AI |
| "BETA UI Availability" / "BETA UI feedback program" | BETA UI |
| "Be sure to check AI-generated content for accuracy." | AI |
| "Bulk import allows you to create and update many records at once." | Importação |
| "%s completed data privacy task to delete user ID \|%s\|" | Privacidade |
| "%s created data privacy task to delete user ID \|%s\|" | Privacidade |
| "%s updated data privacy task to delete user ID \|%s\|" | Privacidade |
| "A color scheme that uses dark-colored elements on a light background." | Aparência |
| "A color scheme that uses light-colored elements on a dark background." | Aparência |
| Diversos fragmentos de templates (ex.: "<% end %>\n", "<div>Your #{config.product_name} Team</div>") | Templates e-mail/messaging |

Muitas outras entradas vazias estão espalhadas pelo arquivo (AI, canais, segurança, notificações, etc.). Para listar todas localmente:

```bash
# No repositório
grep -B1 '^msgstr ""$' i18n/zammad.pt-br.po
```

---

## 2. Código customizado (relatórios, pausas, ATS)

### Strings em inglês que aparecem para o usuário e precisam de pt-BR

Estas strings estão no código mas **não** aparecem no `zammad.pot` (não foram extraídas pelo gerador de catálogo). Para que entrem no fluxo oficial, seria necessário rodar `rails generate zammad:translation_catalog` e depois traduzi-las no Weblate. Para uso local, podem ser adicionadas manualmente ao `zammad.pt-br.po` e/ou trocadas no código por equivalentes em português.

| String (inglês) | Arquivo(s) | Sugestão pt-BR |
|-----------------|------------|----------------|
| `Failed to load report` | `report/pause_indicators.coffee`, `report/user_pauses.coffee`, `report/ticket_time_trackings.coffee` | `Falha ao carregar o relatório` |
| `Cannot perform actions while in pause` | `application/pause_blocker.coffee` | `Não é possível realizar ações enquanto estiver em pausa` |
| `Failed to end pause` | `application/pause_blocker.coffee` | `Falha ao encerrar a pausa` |
| `Delay reason is required` | `user_pause/delay_reason.coffee` | `O motivo da demora é obrigatório` |
| `Delay reason is required when time limit is exceeded` | `user_pause_service.rb` | `O motivo da demora é obrigatório quando o tempo limite é excedido` |
| `User does not have pause control enabled` | `user_pause_service.rb` | `O usuário não tem controle de pausa habilitado` |
| `User is not logged in to pause control` | `user_pause_service.rb` | `O usuário não está logado no controle de pausa` |
| `User is already in pause` | `user_pause_service.rb` | `O usuário já está em pausa` |
| `User is not in pause` | `user_pause_service.rb` | `O usuário não está em pausa` |
| `Active pause not found` | `user_pause_service.rb` | `Pausa ativa não encontrada` |
| `Cannot logout while in pause` | `user_pause_sessions_controller.rb` | `Não é possível sair enquanto estiver em pausa` |
| `No active pause control session` | `user_pause_sessions_controller.rb` | `Nenhuma sessão ativa de controle de pausa` |
| `You do not have permission to use pause control.` | `user_pause_sessions_controller.rb` | `Você não tem permissão para usar o controle de pausa.` |
| `must be after started_at` | `user_pause.rb`, `user_pause_session.rb` | `deve ser posterior a data/hora de início` |

### Strings já em português no código (pt-BR ok no código)

Estas já estão em português nas views/controllers. Para pt-BR não é obrigatório traduzir de novo no `.po` (o msgid pode ser o próprio texto em português e o msgstr igual). Para outros idiomas, elas precisariam estar no catálogo com tradução.

- Relatórios: `Relatório de Pausas de Usuários`, `Relatório de Tempo de Atendimento`, `Indicadores de Pausa`, `Pausas de Usuários`, `Tempo de Atendimento`
- Filtros: `Equipe`, `Aplicar filtro`, `Data Inicial`, `Data Final`, `Tipo de Pausa`, `Tempo excedido`, `Todos`, `Sim`, `Não`, `Agente`, `Nome ou email`, `Pesquisar`
- Status (backend): `Deslogado`, `Em pausa`, `Offline`, `Online`
- Outros: `Pausa`, `Login/Logout`, `Colaborador`, `Status`, `Tempo em pausa`, `Logado`, `Pausa ativa`, `Nenhum registro encontrado`, `Data`, `Hora`, `Hora Fim`, `Tempo Máximo Permitido`, `Duração Total`, `Nome da Pausa/Login/Logout`, `Data de Abertura (Inicial/Final)`, `Data de Fechamento (Inicial/Final)`, `Ticket`, `Número ou título`, `Responsável`, `Data de abertura`, `Data de fechamento`, `Data/Hora de início/término`, `Tempo total de atendimento`, `Tempo do atendimento pausado`, `Estado atual`
- Permissões (seeds/migration): `Pause Indicators`, `User Pauses Report`, `Ticket Time Trackings Report`, `Pause Types`, `Pause Control`, `Ticket Time Tracking`, etc. — essas estão em inglês no backend (labels de permissão) e podem ser traduzidas no .po se forem exibidas na interface.

**No `zammad.pt-br.po` já existem, por exemplo:**

- `Equipe` → `Equipe`
- `Aplicar filtro` → `Aplicar filtro`

---

## 3. Como atualizar o catálogo e testar traduções

### Atualizar o catálogo (extrair novas strings do código)

```bash
rails generate zammad:translation_catalog
```

Isso atualiza `i18n/zammad.pot`. Depois, no Weblate (ou manualmente no `.po`), as novas strings podem ser traduzidas para pt-BR.

### Importar alterações do .po para o banco (testar localmente)

Depois de editar `i18n/zammad.pt-br.po`:

```bash
rails r Translation.sync
```

As alterações passam a aparecer na interface.

### Testar um .po baixado do Weblate

1. Baixar o .po de pt-BR do Weblate.
2. Salvar como `i18n/zammad.pt-br.po`.
3. Rodar `rails r Translation.sync`.

---

## 4. Resumo de ações sugeridas

| Prioridade | Ação |
|-----------|------|
| Alta | Traduzir no `zammad.pt-br.po` (ou no Weblate) as ~99 entradas com `msgstr ""` que forem relevantes para o uso da aplicação. |
| Alta | Adicionar ao código ou ao .po a tradução de **"Failed to load report"** → **"Falha ao carregar o relatório"** nos três relatórios (pause_indicators, user_pauses, ticket_time_trackings). |
| Média | Traduzir no .po as mensagens de erro e bloqueio do controle de pausa (pause_blocker, user_pause_service, user_pause_sessions_controller) listadas na tabela da seção 2. |
| Média | Rodar `rails generate zammad:translation_catalog` para incluir strings do código customizado no `zammad.pot` e depois preencher as traduções em pt-BR no Weblate ou no `.po`. |
| Baixa | Revisar labels de permissões (Pause Indicators, User Pauses Report, etc.) e, se forem exibidas na UI, garantir que tenham entrada no .pot e tradução em pt-BR. |

---

*Documento gerado por varredura no repositório. Última atualização: fevereiro/2025.*

## Atualização: Traduções de IA (pt-BR)

Foram corrigidas e preenchidas no `i18n/zammad.pt-br.po` as seguintes strings da área visual de IA:

- **Menu e títulos:** AI Agent(s), AI Provider, Writing Assistant, Writing Assistant Tools, Ticket Summary, Summary Services, Summary Generation, Feedback & Logs, Legal Information, Experimental.
- **Formulários e ações:** New AI Agent, New Writing Assistant Tool, Search for AI agents, Search for writing assistant tools, Download Feedback, Download Error Logs, Submit (já existia como "Enviar").
- **Mensagens de erro e estado:** AI provider is not configured / missing / not supported, AI provider URL/Model/Token not set, AI agent result content..., AI assistance text tool is inactive/invalid, AI service result is missing expected keys, AI usage and feedback log, The AI Provider is not accessible, Enter the instruction/role description for the AI agent, Unused AI agent, AI agent used in, This service allows you to connect Zammad with an AI provider, The download could not be started..., Manage AI agents of your system.
- **Descrições:** AI agents enable streamlined processing..., Writing Assistant (e variantes) que estavam erroneamente como "Aguardando em %s" foram corrigidas para "Assistente de Redação" / "Ferramentas do Assistente de Redação".

Na view **Ticket Summary** (`app/assets/javascripts/app/views/ai/ticket_summary.jst.eco`), o botão "Submit" usa `<%- @T('Submit') %>` (tradução "Enviar" em pt-BR).

**Customizações via banco (sem editar .po):** As traduções customizadas (ticket/chamado/tíquete, AI, etc.) estão em `lib/translation_overrides_pt_br.rb`. São aplicadas após `Translation.sync` no init Docker ou manualmente com:
`bundle exec rake zammad:translation_overrides_pt_br`
Para adicionar novas entradas: edite o hash `OVERRIDES` em `lib/translation_overrides_pt_br.rb` (source => target).
