# Contexto do Projeto Zammad ATS - Para Agentes de IA

## 📋 Visão Geral do Projeto

Este é um fork customizado do **Zammad** (sistema de helpdesk/ticketing open source) para a empresa **ATS Informática**. O projeto está baseado na versão **7.0-alpha** do Zammad e inclui diversas customizações específicas.

### Estrutura de Diretórios
- **Workspace:** `E:\Projetos\zammad`
- **Código fonte:** `E:\Projetos\zammad\source`
- **Git configurado em:** `E:\Projetos\zammad\source`

### Repositórios Git
- **Origin (fork):** `https://github.com/paulo-atsinformatica/zammad.git`
- **Upstream (oficial):** `https://github.com/zammad/zammad.git`
- **Branch principal:** `developer`

### Docker Registry
- **Imagem:** `ghcr.io/paulo-atsinformatica/zammad`
- **Tags atuais:** `7.0.1`, `latest`

---

## 🎨 Customizações de Branding ATS

### Cores
- **Cor primária:** Vermelho ATS (#C41E3A ou similar)
- Botões primários alterados de verde para vermelho
- Ícones de report/cog com hover vermelho
- Switch, ícone plus, links em modo escuro
- Stat-dial vermelho
- Fundos e links ativos

### Logo
- Logo ATS branco substituindo o logo Zammad
- Aplicado em splash screen, sidebar, favicon

### Arquivos principais modificados:
- `app/assets/stylesheets/zammad.scss` - Estilos globais
- `public/assets/` - Logos e ícones

---

## ⏱️ Sistema de Controle de Pausas

### Funcionalidade
Sistema completo para controle de pausas dos agentes, permitindo:
- Login/Logout no sistema de pausas
- Tipos de pausa configuráveis (Almoço, Banheiro, etc.)
- Tempo máximo por tipo de pausa
- Relatórios de pausas por usuário
- Indicadores em tempo real

### Modelos Criados
- `PauseType` - Tipos de pausa (`app/models/pause_type.rb`)
- `UserPause` - Registro de pausas (`app/models/user_pause.rb`)
- `UserPauseSession` - Sessões de pausa (`app/models/user_pause_session.rb`)

### Controllers
- `PauseTypesController` - CRUD de tipos de pausa
- `UserPausesController` - Controle de pausas do usuário
- `UserPauseSessionsController` - Sessões de login/logout
- `UserPausesReportsController` - Relatório de pausas
- `PauseIndicatorsReportsController` - Indicadores em tempo real

### Frontend (CoffeeScript)
- `app/assets/javascripts/app/controllers/user_status_bar.coffee` - Barra de status do usuário
- `app/assets/javascripts/app/controllers/manage/pause_types.coffee` - Gestão de tipos
- `app/assets/javascripts/app/controllers/report/user_pauses.coffee` - Relatório de pausas
- `app/assets/javascripts/app/controllers/report/pause_indicators.coffee` - Indicadores
- `app/assets/javascripts/app/controllers/pause_blocker.coffee` - Bloqueio quando em pausa

### Migrações
- `20251224120000_create_pause_types.rb`
- `20251224120001_create_user_pauses.rb`
- `20260119120000_create_user_pause_sessions.rb`
- `20260119130000_remove_pause_control_fields_from_users.rb`

### Policies
- `pause_types_controller_policy.rb`
- `user_pauses_reports_controller_policy.rb`
- `pause_indicators_reports_controller_policy.rb`

---

## ⏲️ Sistema de Time Tracking (Tempo de Atendimento)

### Funcionalidade
Controle de tempo de atendimento por ticket:
- Iniciar/Pausar/Parar contagem de tempo
- Troca entre tickets (pausa automática do anterior)
- Relatório de tempo de atendimento
- Integração com estado do ticket (desabilita quando fechado)

### Modelo
- `TicketTimeTracking` (`app/models/ticket_time_tracking.rb`)

### Controller
- `TicketTimeTrackingsController` (`app/controllers/ticket_time_trackings_controller.rb`)
  - Endpoints: `start`, `pause`, `resume`, `stop`, `switch`, `current`

### Service
- `TicketTimeTrackingService` (`app/services/ticket_time_tracking_service.rb`)

### Frontend
- `app/assets/javascripts/app/controllers/ticket_zoom/time_tracking.coffee`
  - Player de controle de tempo no ticket
  - Diálogo de troca de ticket
  - Atualização em tempo real via WebSocket

### Relatório
- `TicketTimeTrackingsReportsController`
- `app/assets/javascripts/app/controllers/report/ticket_time_trackings.coffee`
- Coluna "Tempo total de atendimento" adicionada

### Rotas
- `config/routes/time_tracking.rb`

### Migrações
- `20251224120002_create_ticket_time_trackings.rb`
- `20251224120003_add_time_tracking_fields_to_users.rb`
- `20251224130000_add_ticket_time_tracking_permission.rb`

---

## 👤 Campos Customizados de Usuário

### Campos adicionados ao objeto User:
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `cargo` | input | Cargo do usuário |
| `superiorhierarquico` | input | Superior hierárquico |
| `equipe` | input | Equipe |
| `observacao` | textarea (10000 chars, 7 linhas) | Observações |
| `bloqueado` | boolean (Sim/Não) | Se está bloqueado |

### Características:
- Campos não editáveis/deletáveis via interface (`editable: false`, `to_delete: false`)
- Valores são editáveis
- Visíveis em todas as telas (create, edit, view)

### Migração
- `20260119150000_add_user_default_fields.rb`

---

## 🏢 Campos Customizados de Organização

### Campos adicionados ao objeto Organization:
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `razaosocial` | input | Razão Social |
| `cpf` | input | CPF |
| `cnpj` | input | CNPJ |
| `codcliente` | input | Código do Cliente |
| `perfildeacesso` | input | Perfil de Acesso |
| `classificacao` | input | Classificação |
| `cep` | input | CEP |
| `endereco` | input | Endereço |
| `numero` | input | Número |
| `complemento` | input | Complemento |
| `bairro` | input | Bairro |
| `cidade` | input | Cidade |
| `estado` | input | Estado |
| `pais` | input | País |
| `grupoeconomico` | input | Grupo Econômico |
| `observacao` | textarea (10000 chars, 7 linhas) | Observações |
| `segmento` | select | Segmento (opções configuráveis) |
| `modulos` | multiselect | Módulos (opções configuráveis) |

### Migração
- `20260119151000_add_organization_default_fields.rb`
- `20260120230000_enable_org_segmento_modulos_editable.rb` (habilita edição de segmento/modulos)

---

## 🔍 Busca por Campos Customizados

### Funcionalidade
Busca de organizações no ticket por:
- CNPJ
- CPF
- Código do Cliente (CodCliente)
- Grupo Econômico

### Arquivos modificados:
- `app/models/organization/search_index.rb` - Indexação para Elasticsearch
- `script/reindex_organizations.rb` - Script de reindexação

### Como funciona:
Os campos são indexados com sufixos `_text` e `_clean` (sem caracteres especiais) para busca eficiente.

---

## 🐛 Bug Fixes Aplicados do Upstream

### Aplicados com sucesso (Janeiro 2026):
| Issue | Descrição | Arquivo |
|-------|-----------|---------|
| #5916 | Texto azul após menção | `jquery.textmodule.js` |
| #5904 | Tags não exibidas no Excel | `excel_sheet.rb` |
| #5884 | Preservar dimensões de imagem ao encaminhar | `utils.coffee` |
| #5893 | Erro null ao atualizar estado com checklist | `ticket_zoom.coffee` |
| #5787 | Erros de formatação heading + backspace | `zammad.scss` |

### Não aplicados (conflitos extensos):
- Bug fixes de AI/IA (módulo muito diferente do upstream)
- Features de Desktop View (muitas dependências)

---

## ⚠️ Correções Importantes Feitas

### Handler Global AJAX para 409
**Arquivo:** `app/assets/javascripts/app/lib/app_post/ajax.coffee`

Adicionado `return if status is 409` para ignorar erros 409 no handler global, permitindo que controllers específicos tratem o erro (ex: diálogo de troca de ticket no time tracking).

### Permissão para ticket_stats
**Arquivo:** `app/policies/controllers/tickets_controller_policy.rb`

Adicionada permissão para ação `stats`.

---

## 📁 Estrutura de Arquivos Principais

```
source/
├── app/
│   ├── assets/
│   │   ├── javascripts/app/
│   │   │   ├── controllers/
│   │   │   │   ├── ticket_zoom/
│   │   │   │   │   └── time_tracking.coffee
│   │   │   │   ├── report/
│   │   │   │   │   ├── user_pauses.coffee
│   │   │   │   │   ├── ticket_time_trackings.coffee
│   │   │   │   │   └── pause_indicators.coffee
│   │   │   │   ├── user_status_bar.coffee
│   │   │   │   └── manage/pause_types.coffee
│   │   │   ├── lib/
│   │   │   │   └── app_post/ajax.coffee
│   │   │   └── views/
│   │   │       └── report/
│   │   │           ├── user_pauses.jst.eco
│   │   │           └── ticket_time_trackings.jst.eco
│   │   └── stylesheets/
│   │       └── zammad.scss
│   ├── controllers/
│   │   ├── ticket_time_trackings_controller.rb
│   │   ├── pause_types_controller.rb
│   │   ├── user_pauses_controller.rb
│   │   └── *_reports_controller.rb
│   ├── models/
│   │   ├── ticket_time_tracking.rb
│   │   ├── pause_type.rb
│   │   ├── user_pause.rb
│   │   ├── user_pause_session.rb
│   │   └── organization/search_index.rb
│   ├── services/
│   │   ├── ticket_time_tracking_service.rb
│   │   └── user_pause_service.rb
│   └── policies/controllers/
│       └── *_policy.rb
├── config/routes/
│   └── time_tracking.rb
├── db/migrate/
│   └── 2025*/2026* (migrações customizadas)
└── .dev/
    ├── ai-agent-instructions.md
    └── custom-branding-ats-modifications.md
```

---

## 🔧 Comandos Úteis

### Build Docker
```powershell
cd E:\Projetos\zammad
$env:DOCKER_BUILDKIT=0
$COMMIT_SHA = git -C source rev-parse HEAD
docker build --build-arg COMMIT_SHA=$COMMIT_SHA -t ghcr.io/paulo-atsinformatica/zammad:latest -t ghcr.io/paulo-atsinformatica/zammad:7.1.0 -f source/Dockerfile source
```

### Push Docker (ghcr.io)
```powershell
# Faça login uma vez se ainda não: docker login ghcr.io (use um PAT com write:packages)
docker push ghcr.io/paulo-atsinformatica/zammad:7.1.0
docker push ghcr.io/paulo-atsinformatica/zammad:latest
```

### Git - Atualizar do upstream
```powershell
cd E:\Projetos\zammad\source
git fetch upstream
# Para aplicar um fix específico:
git cherry-pick <commit-hash> --no-commit
```

### Reindexar organizações
```powershell
# Dentro do container
rails runner script/reindex_organizations.rb
```

---

## 🚨 Problemas Conhecidos / Limitações

1. **Módulo de AI:** O código de AI/IA divergiu muito do upstream. Bug fixes de AI não podem ser aplicados sem grandes refatorações.

2. **Desktop View:** As features de Desktop View do upstream dependem de dezenas de commits anteriores e não são aplicáveis isoladamente.

3. **Elasticsearch:** Após adicionar novos campos de busca, é necessário reindexar as organizações.

4. **WebSocket:** Algumas funcionalidades dependem de WebSocket (PushMessages) para atualização em tempo real.

---

## 📝 Notas para o Agente

1. **Sempre use PowerShell** no Windows (não use `&&` ou `||`, use `;` para separar comandos)

2. **Git está em `source/`**, não na raiz do projeto

3. **Arquivos .coffee** são CoffeeScript (sintaxe diferente de JavaScript)

4. **Arquivos .jst.eco** são templates EJS para o frontend legado

5. **Políticas** seguem o padrão `Controllers::NomeControllerPolicy`

6. **Migrações** devem verificar se colunas existem antes de remover (`column_exists?`)

7. **ObjectManager::Attribute** usa `object_lookup_id: ObjectLookup.by_name('Model')` para queries

8. **Usuário prefere respostas em Português**

---

## 📞 Contato
- **Usuário:** Paulo Henrique
- **Empresa:** ATS Informática
- **Repositório:** github.com/paulo-atsinformatica/zammad
