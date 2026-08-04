# Guia: Sincronizar com o repositório original (Zammad) sem perder customizações ATS

Este guia descreve como trazer as alterações do repositório oficial do Zammad para o seu fork, preservando **branding ATS** e o **sistema de pausas/tempo de atendimento**.

---

## 1. Visão geral

- **Origin:** seu fork (`paulo-atsinformatica/zammad`)
- **Upstream:** repositório original (`zammad/zammad`)
- **Sua branch de trabalho:** `developer` (ou a branch onde estão as customizações)
- **Branch do upstream para sincronizar:** normalmente `develop` (desenvolvimento) ou `stable-6.4` / outra `stable-*` (produção)

Ao fazer **merge** do upstream na sua branch, podem ocorrer **conflitos** em arquivos que você modificou (ex.: `zammad.scss`). A regra é: **em arquivos listados na seção 4, em caso de conflito, preserve as alterações ATS (nossas)**.

---

## 2. Pré-requisitos

1. **Working tree limpo**  
   Não pode ter alterações não commitadas.  
   - Commit ou stash de tudo:  
     `git status`  
     `git add .` e `git commit -m "..."` ou `git stash push -u -m "WIP antes do sync"`

2. **Backup da branch atual**  
   Criar uma branch de backup antes do merge:  
   `git branch backup-ats-antes-sync-YYYYMMDD`  
   (troque YYYYMMDD pela data). Assim você sempre pode voltar com `git checkout backup-ats-antes-sync-YYYYMMDD` se algo der errado.

---

## 3. Passo a passo da sincronização

Execute no diretório do repositório (`source`).

**Atalho:** você pode usar o script PowerShell que automatiza os passos 3.1 e 3.2 (e cria o backup). Veja a [seção 9](#9-script-automatizado-opcional) no final do guia.

### 3.1 Buscar as últimas alterações do upstream

```powershell
git fetch upstream
```

### 3.2 Escolher a branch do upstream a ser integrada

- **Desenvolvimento (novidades, possíveis instabilidades):**  
  `upstream/develop`
- **Produção (mais estável):**  
  `upstream/stable-6.4` (ou a stable mais recente que você usa)

Exemplo assumindo que você quer sincronizar com `develop`:

```powershell
# Garantir que está na sua branch de customizações
git checkout developer

# Criar backup (recomendado)
git branch backup-ats-antes-sync-20250220

# Fazer o merge do upstream/develop na sua branch
git merge upstream/develop -m "Sync upstream develop - manter customizações ATS"
```

### 3.3 Resolver conflitos

Se o Git informar conflitos:

1. Abra os arquivos listados como “both modified”.
2. **Para os arquivos listados na seção 4 (lista ATS):**  
   Mantenha o conteúdo **nosso** (branding e funcionalidades ATS). Incorpore apenas trechos do upstream que forem claramente novos (por exemplo, novas variáveis CSS em outro bloco) se fizer sentido.
3. **Para qualquer outro arquivo:**  
   Avalie caso a caso: pode ser correção de bug ou feature do upstream que você quer manter; então combine “theirs” com “ours” conforme necessário.
4. Após editar:  
   `git add <arquivo>`  
   Quando todos os conflitos estiverem resolvidos:  
   `git commit` (o Git abrirá a mensagem do merge; pode apenas salvar e fechar).

Dica: para um arquivo específico, se quiser **manter 100% a nossa versão** em um conflito:

```powershell
git checkout --ours -- caminho/do/arquivo
git add caminho/do/arquivo
```

Use isso com cuidado: só em arquivos que são puramente customização ATS (veja seção 4).

---

## 4. Lista de arquivos ATS: preservar em conflitos

Em caso de **conflito** nestes arquivos, **priorize manter as alterações ATS (versão “ours”)**. Só aceite trechos do upstream se forem mudanças claras e compatíveis (ex.: nova variável CSS em outro lugar).

### 4.1 Branding (cores e estilos)

| Arquivo | Observação |
|--------|------------|
| `app/assets/stylesheets/zammad.scss` | Cores ATS (#480404, variáveis, menu, botões) |
| `app/assets/stylesheets/knowledge_base.scss` | Background vermelho ATS |
| `app/frontend/apps/desktop/styles/tokens.css` | Tokens verde → vermelho |
| `app/frontend/apps/mobile/styles/tokens.css` | Tokens verde → vermelho |
| `public/assets/images/icons.svg` | Ícones mood-supergood, stopwatch |
| `app/assets/javascripts/app/controllers/_dashboard/stats/ticket_waiting_time.coffee` | Cor do stat-dial |
| `app/views/init/spinner-loading.html.erb` | Cor de fundo do loading |

### 4.2 Sistema de pausas e tempo de atendimento (arquivos só existem no fork)

Estes arquivos **não existem** no Zammad original. O merge **não deve removê-los**. Se o Git mostrar conflito “added by both”, mantenha o conteúdo nosso.

**Backend – Models**

- `app/models/pause_type.rb`
- `app/models/user_pause.rb`
- `app/models/user_pause_session.rb`
- `app/models/ticket_time_tracking.rb`

**Backend – Controllers**

- `app/controllers/pause_types_controller.rb`
- `app/controllers/user_pauses_controller.rb`
- `app/controllers/user_pause_sessions_controller.rb`
- `app/controllers/user_states_controller.rb`
- `app/controllers/ticket_time_trackings_controller.rb`
- `app/controllers/user_pauses_reports_controller.rb`
- `app/controllers/ticket_time_trackings_reports_controller.rb`
- `app/controllers/pause_indicators_reports_controller.rb`

**Backend – Services**

- `app/services/user_pause_service.rb`
- `app/services/ticket_time_tracking_service.rb`

**Backend – Policies**

- `app/policies/controllers/pause_types_controller_policy.rb`
- `app/policies/controllers/user_pauses_reports_controller_policy.rb`
- `app/policies/controllers/ticket_time_trackings_reports_controller_policy.rb`

**Backend – Rotas**

- `config/routes/time_tracking.rb`

**Backend – Migrações** (não apagar; podem não conflitar)

- `db/migrate/20251224120000_create_pause_types.rb`
- `db/migrate/20251224120001_create_user_pauses.rb`
- `db/migrate/20251224120002_create_ticket_time_trackings.rb`
- `db/migrate/20251224120003_add_time_tracking_fields_to_users.rb`
- `db/migrate/20251224120004_add_pause_type_permission.rb`
- `db/migrate/20251224130000_add_ticket_time_tracking_permission.rb`
- `db/migrate/20251227130000_add_pause_control_permissions.rb`
- `db/migrate/20260119120000_create_user_pause_sessions.rb`
- `db/migrate/20260119130000_remove_pause_control_fields_from_users.rb`

**Frontend (CoffeeScript / legado)**

- `app/assets/javascripts/app/controllers/user_status_bar.coffee`
- `app/assets/javascripts/app/controllers/manage/pause_types.coffee`
- `app/assets/javascripts/app/controllers/report/user_pauses.coffee`
- `app/assets/javascripts/app/controllers/report/ticket_time_trackings.coffee`
- `app/assets/javascripts/app/controllers/application/pause_blocker.coffee`
- `app/assets/javascripts/app/controllers/user_pause/delay_reason.coffee`
- `app/assets/javascripts/app/controllers/ticket_zoom/time_tracking.coffee`
- `app/assets/javascripts/app/controllers/pause_blocker.coffee` (se existir)
- `app/assets/javascripts/app/models/pause_type.coffee`

**Specs e factories**

- `spec/models/pause_type_spec.rb`
- `spec/models/user_pause_spec.rb`
- `spec/models/ticket_time_tracking_spec.rb`
- `spec/factories/pause_type.rb` (se existir)
- `spec/factories/user_pause.rb` (se existir)
- `spec/factories/ticket_time_tracking.rb` (se existir)
- `spec/factories/user_pause_session.rb` (se existir)

**Documentação e scripts**

- `.dev/custom-branding-ats-modifications.md`
- `.dev/sync-upstream-guide.md` (este arquivo)
- `doc/developer_manual/cookbook/ats-pause-control.md`

Se o **upstream** tiver alterado algum arquivo que **também** existe na lista acima (por exemplo `app/models/user.rb` ou `app/models/ticket.rb`), aí pode haver conflito: resolva manualmente, mantendo as partes ATS (referências a pausas, time tracking, etc.) e incorporando as mudanças do upstream que forem seguras.

---

## 5. Após o merge

1. **Testes**  
   Rodar testes do backend e, se possível, do frontend:  
   `bundle exec rspec`  
   `pnpm test` (ou o comando de testes do frontend que você usa).

2. **Migrações**  
   Se o upstream tiver novas migrações:  
   `bundle exec rails db:migrate`  
   (em ambiente de dev/staging primeiro.)

3. **Assets**  
   Rebuild dos assets:  
   `pnpm install` (se `package.json` mudou)  
   Build conforme seu processo (por exemplo via Docker ou script de build).

4. **Smoke test**  
   Abrir a aplicação, testar login, um ticket, barra de pausas e tempo de atendimento, e relatórios de pausas, para garantir que nada quebrou.

---

## 6. Enviar para o seu fork

Quando estiver tudo estável na sua máquina:

```powershell
git push origin developer
```

Se a branch tiver outro nome, use esse nome no lugar de `developer`.

---

## 7. Resumo rápido (checklist)

- [ ] Working tree limpo (`git status`)
- [ ] Backup da branch criado (`git branch backup-ats-...`)
- [ ] `git fetch upstream`
- [ ] `git checkout developer` (ou sua branch)
- [ ] `git merge upstream/develop` (ou `upstream/stable-X.X`)
- [ ] Conflitos resolvidos; em arquivos ATS priorizar “ours”
- [ ] Testes rodando
- [ ] Migrações e assets atualizados
- [ ] `git push origin developer`

---

## 8. Se algo der errado

- **Desfazer o merge (antes de dar commit):**  
  `git merge --abort`

- **Voltar para o estado antes do merge (já deu commit):**  
  `git reset --hard backup-ats-antes-sync-YYYYMMDD`  
  (use o nome da branch de backup que você criou.)

Isso restaura sua branch ao estado anterior ao merge; você pode tentar o merge de novo ou analisar os conflitos com mais calma.

---

---

## 9. Script automatizado (opcional)

Na raiz do repositório (`source`), você pode rodar:

```powershell
# Sincronizar com upstream/develop (padrão)
.\.dev\scripts\sync-upstream.ps1

# Sincronizar com uma branch stable
.\.dev\scripts\sync-upstream.ps1 -UpstreamBranch stable-6.4

# Apenas simular (não executa fetch/merge)
.\.dev\scripts\sync-upstream.ps1 -DryRun
```

O script verifica working tree limpo e remote `upstream`, cria uma branch de backup com data/hora, faz `git fetch upstream` e `git merge upstream/<branch>`. Se houver conflitos, lista os arquivos e lembra de consultar este guia.

---

**Referências**

- Repositório original: https://github.com/zammad/zammad  
- Documentação das modificações ATS: [.dev/custom-branding-ats-modifications.md](.dev/custom-branding-ats-modifications.md)  
- Controle de pausas: [doc/developer_manual/cookbook/ats-pause-control.md](../doc/developer_manual/cookbook/ats-pause-control.md)
