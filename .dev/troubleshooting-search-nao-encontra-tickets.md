# Troubleshooting: tickets existentes não aparecem na busca

## Sintoma

Busca por número/texto de um ticket que existe no Zammad não retorna resultado
nenhum. `Ticket.search` não lança exceção — só devolve array vazio. Tickets
mais antigos (indexados há dias/semanas) continuam pesquisáveis; só os
recentes somem.

## Causa raiz

`SearchIndexJob` (indexação incremental no Elasticsearch) e `TriggerWebhookJob`
(disparo de webhooks configurados em Triggers) **dividem a mesma fila**
`default` do Delayed::Job — nenhum dos dois define `queue_as` próprio, então
caem no default do `ApplicationJob`.

Se um webhook aponta pra um endpoint que trava (aceita a conexão TCP/TLS mas
nunca responde), cada tentativa do `TriggerWebhookJob` fica presa até estourar
timeout (~30s), com múltiplos retries por ticket. Isso enche a fila `default`
com milhares de jobs pendentes, e o `SearchIndexJob` — enfileirado atrás —
não roda a tempo. Resultado: tickets novos/atualizados nunca chegam ao índice
do Elasticsearch, e a busca não os encontra.

O Elasticsearch em si costuma estar saudável (status `yellow` é esperado e
inofensivo em cluster de 1 node só — significa réplicas não alocadas, não
falta de dados).

## Incidente de 2026-07-27

- Trigger #7 ("Integração Warehouse") chama o Webhook #2 ("Metrics Warehouse"),
  apontando pra `https://webhook.atsticket.atsinformatica.com.br/webhook/zammad`.
- Esse endpoint é servido pelo container `app-<hash>` da imagem
  `middleware-ats-ticket` (mesmo serviço que atende `/blip/*`).
- O container estava vivo e respondendo bem em `/blip/*` e `/health`, mas a
  rota `/webhook/zammad` especificamente ficava pendurada (TLS completa, 0
  bytes de resposta, timeout).
- Fila `default` acumulou **3631 jobs pendentes**, 134 `TriggerWebhookJob`
  com múltiplas tentativas falhadas.
- Ticket criado 2h30 antes não estava indexado no ES
  (`GET /zammad_production_ticket/_doc/<id>` → `found: false`).
- **Fix:** reiniciar o container `app-<hash>` do middleware resolveu — a
  rota específica travada voltou a responder normalmente após o restart.

## Passo a passo de diagnóstico

1. **Confirmar que o ticket existe no Postgres mas não no índice:**
   ```bash
   docker exec <railsserver> bash -c "cd /opt/zammad && bin/rails runner \"
   t = Ticket.find_by(number: 'NUMERO')
   puts t ? \\\"ID: #{t.id}\\\" : 'nao encontrado'
   \""
   docker exec <railsserver> curl -s "http://<elasticsearch>:9200/zammad_production_ticket/_doc/<ID>?pretty"
   ```
   Se `found: false` com ticket recente, indexação está atrasada/parada.

2. **Checar saúde do cluster ES** (yellow com só réplicas unassigned é normal
   em single-node; red ou muitos shards primários unassigned não é):
   ```bash
   docker exec <railsserver> curl -s "http://<elasticsearch>:9200/_cluster/health?pretty"
   ```

3. **Checar acúmulo na fila do Delayed::Job** — se `default` tiver milhares de
   jobs pendentes, a indexação está atrás de um engarrafamento, não é
   problema do ES:
   ```bash
   docker exec <railsserver> bash -c "cd /opt/zammad && bin/rails runner \"
   puts Delayed::Job.group(:queue).count
   puts Delayed::Job.where('attempts > 0').group(:handler).count.size
   \""
   ```
   (`handler` é serializado, então agrupar por classe real exige inspecionar
   o YAML — mais prático é listar `Delayed::Job.where('attempts > 0')` e
   olhar o `name`/`payload_object.job_data['job_class']`.)

4. **Identificar o job/trigger causando o engarrafamento:**
   ```bash
   docker exec <railsserver> bash -c "cd /opt/zammad && bin/rails runner \"
   t = Trigger.find(<id>)
   puts t.perform.inspect   # mostra webhook_id se for notification.webhook
   w = Webhook.find(<webhook_id>)
   puts w.endpoint
   \""
   ```

5. **Testar o endpoint do webhook direto** (de dentro do container Zammad,
   depois de dentro do container de destino em localhost, pra isolar
   rede/proxy vs. aplicação travada):
   ```bash
   docker exec <railsserver> curl -sv -m 10 -o /dev/null -w "HTTP %{http_code} | %{time_total}s\n" <url>
   docker exec <container-destino> curl -sv -m 10 -o /dev/null -w "HTTP %{http_code} | %{time_total}s\n" http://localhost:<porta><path>
   ```
   TLS completa mas 0 bytes/timeout = processo vivo mas handler travado
   (não é DNS/firewall — a app aceitou a conexão).

6. **Se a app de destino estiver com uma rota específica travada mas outras
   respondendo bem** (health check OK, outras rotas OK): reiniciar o
   container costuma bastar — indica handler preso (deadlock, conexão de
   downstream nunca liberada, etc.), não crash geral.

## Depois de resolver

- Tickets criados durante a janela de engarrafamento podem ter ficado sem
  indexar mesmo depois da fila esvaziar, se o job de indexação correspondente
  tiver sido descartado por `attempts` excedido. Rodar reindex incremental
  pra garantir:
  ```bash
  docker exec <railsserver> bash -c "cd /opt/zammad && bin/rails runner \"
  Ticket.where('updated_at > ?', 6.hours.ago).find_each { |t| t.search_index_update_backend }
  \""
  ```

## Prevenção (ainda não implementado — considerar)

- Dar fila própria ao `SearchIndexJob` (`queue_as :search_index`) com worker
  dedicado, pra webhooks lentos/travados nunca bloquearem indexação.
- Adicionar timeout curto e explícito no `TriggerWebhookJob` (hoje o timeout
  observado de ~30s por tentativa é alto pra um job que roda no mesmo pool
  compartilhado).
- Monitorar `Delayed::Job.where(queue: 'default').count` como métrica de
  saúde — acima de algumas centenas já indica problema a caminho.
- `/health` do middleware não pega esse tipo de falha (só checava liveness
  geral, não cada rota). Se possível, health check mais específico por rota
  crítica.
