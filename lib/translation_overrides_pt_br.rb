# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customizações ATS: overrides de tradução pt-BR aplicados como se fossem feitos pela interface
# (não alteram o .po; atualizam apenas o banco).
# Upstream: translations.zammad.org; PRs que alterem .po são rejeitados.

module TranslationOverridesPtBr
  LOCALE = 'pt-br'

  # source (msgid) => target (tradução desejada)
  OVERRIDES = {
    # Padronização: ticket/Ticket/tickets/Tickets (sem Chamado/Tíquete)
    'Ticket' => 'Ticket',
    'Tickets' => 'Tickets',
    'Ticket %s created!' => 'Ticket %s criado!',
    'Ticket %s merged.' => 'Ticket %s fundido.',
    'Ticket (censored):' => 'Ticket (censurado):',
    'Ticket update' => 'Atualização de ticket',
    'Ticket |%s| will escalate soon!' => 'Ticket |%s| irá escalonar em breve!',
    'Closed Tickets' => 'Tickets fechados',
    'Closed tickets' => 'tickets fechados',
    'Found tickets' => 'tickets encontrados',
    'New & open tickets' => 'Tickets novos e abertos',
    'Open Tickets' => 'Tickets abertos',
    'Pending tickets' => 'Tickets pendentes',
    'Subscribed tickets' => 'Tickets inscritos',
    'closed tickets' => 'tickets fechados',
    'open tickets' => 'tickets abertos',
    'Tickets assigned to me: %s of %s' => 'Tickets atribuídos a mim: %s de %s',
    'Tickets of Organization' => 'Tickets da organização',
    'Tickets of User' => 'Tickets do usuário',
    'Tickets bulk edit' => 'Edição em massa de tickets',
    'Archive ticket target state' => 'Estado de destino do ticket arquivado',
    'Ticket Group Dispatcher' => 'Despachante de grupo de tickets',
    'Triggered because ticket will escalate soon' => 'Acionado porque o ticket irá escalonar em breve',
    'Not Assigned' => 'Não atribuído',
    'Ticket Hook' => 'Amarração do ticket',
    'Ticket Hook Divider' => 'Divisor do hook do ticket',
    'Ticket Hook Position' => 'Posição da amarração do ticket',
    'Ticket Last Contact Behaviour' => 'Comportamento do último contato do ticket',
    'Ticket Number Format' => 'Formato do número do ticket',
    'Ticket Number Increment' => 'Incremento do número do ticket',
    'Ticket Number Increment Date' => 'Data de incremento do número do ticket',
    'Ticket Auto Assignment' => 'Atribuição automática de tickets',
    'Ticket Categorizer' => 'Categorizador de tickets',
    'Ticket Conditions Expert Mode' => 'Modo especialista em condições de ticket',
    'Ticket Conditions Regular Expression Operators' => 'Operadores de expressão regular para condições de ticket',
    'Ticket Count' => 'Contagem de tickets',
    'Ticket Customer' => 'Cliente do ticket',
    'Ticket Duplicate Detection' => 'Detecção de tickets duplicados',
    # IA (strings que podem estar vazias ou em inglês no upstream)
    'AI Agents' => 'Agentes de IA',
    'AI Provider' => 'Provedor de IA',
    'AI Provider Config' => 'Configuração do provedor de IA',
    'AI Writing Assistant Tools' => 'Ferramentas do assistente de escrita por IA',
    'AI Summary' => 'Resumo por IA',
    'Ticket Summary' => 'Resumo do ticket',

    # Relatórios e Controle de Pausas (strings customizadas ATS)
    'Attendance Report' => 'Relatório de Atendimento',
    'Pause Types' => 'Tipos de Pausa',
    'Pause Control' => 'Controle de Pausas',
    'Allow user to manage pause states (online, offline, pause).' => 'Permitir que o usuário gerencie estados de pausa (online, offline, pausa).',
    'Manage pause types of your system.' => 'Gerenciar tipos de pausa do seu sistema.',
    'Pause Indicators' => 'Indicadores de Pausa',
    'User Pauses Report' => 'Relatório de Pausas de Usuários',
    'Access to the Pause Indicators report.' => 'Acesso ao relatório de Indicadores de Pausa.',
    'Access to the User Pauses report.' => 'Acesso ao relatório de Pausas de Usuários.',
    'Ticket Time Trackings Report' => 'Relatório de Tempo de Atendimento',
    'Access to the Ticket Time Trackings report.' => 'Acesso ao relatório de Tempo de Atendimento.',
    'Failed to load report' => 'Falha ao carregar relatório',
    'You do not have permission to use pause control.' => 'Você não tem permissão para usar o controle de pausas.',
    'Nenhuma equipe cadastrada. Preencha o campo Equipe nos usuários.' => 'Nenhuma equipe cadastrada. Preencha o campo Equipe nos usuários.',

    # Mensagens de bloqueio / permissão.
    #
    # As mensagens do backend passam por App.i18n.translateContent no frontend
    # (app/controllers/_plugin/notify.coffee), então dá para traduzi-las aqui
    # sem alterar arquivos do upstream — inclusive as que o Zammad não marca
    # com __() e que por isso nunca chegariam ao catálogo.
    #
    # PunditPolicy#not_authorized monta a string como "Not authorized (motivo)!",
    # por isso os msgid abaixo incluem esse formato literal.
    'Not authorized' => 'Sem autorização',
    'Authorization failed' => 'Falha na autorização',
    'Not authorized (admin permission required)!' => 'Sem autorização: esta ação exige permissão de administrador.',
    'Not authorized (agent permission required)!' => 'Sem autorização: esta ação exige permissão de agente.',
    'Not authorized (you can only delete your own notes)!' => 'Sem autorização: você só pode excluir as suas próprias anotações.',
    'Not authorized (communication articles cannot be deleted)!' => 'Sem autorização: artigos de comunicação (e-mail, chat) não podem ser excluídos.',
    'Not authorized (note is too old to be deleted)!' => 'Sem autorização: esta anotação é antiga demais para ser excluída.',
    'Not authorized (service disabled)!' => 'Sem autorização: este recurso está desativado nas configurações.',
    'Authentication required' => 'É necessário estar autenticado.',
    'Saving failed.' => 'Não foi possível salvar.',
    'Cannot follow-up on a closed ticket. Please create a new ticket.' => 'Não é possível dar continuidade a um ticket fechado. Abra um ticket novo.',
    'You have insufficient permissions to mention other users.' => 'Você não tem permissão para mencionar outros usuários.',

    # Relatório personalizado (feature ATS).
    'Custom Report' => 'Relatório Personalizado',
    'Custom Reports' => 'Relatórios Personalizados',
    'New Report' => 'Novo Relatório',
    'Report about' => 'Relatório sobre',
    'Visible for' => 'Visível para',
    'Only me' => 'Somente eu',
    'Members of selected groups' => 'Membros dos grupos selecionados',
    'Personal view' => 'Visão pessoal',
    'Generations' => 'Gerações',
    'Generate CSV' => 'Gerar CSV',
    'No filter' => 'Sem filtro',
    'condition(s)' => 'condição(ões)',
    'row(s)' => 'linha(s)',
    'Queued' => 'Na fila',
    'Generating' => 'Gerando',
    'Ready' => 'Pronto',
    'Counting rows...' => 'Contando linhas...',
    'Requested' => 'Solicitado',
    'Progress' => 'Progresso',
    'No report found. Create one to get started.' => 'Nenhum relatório encontrado. Crie um para começar.',
    'No generation yet.' => 'Nenhuma geração ainda.',
    'Reports are generated in the background so that a large export does not affect the system. You can keep working while it runs.' => 'Os relatórios são gerados em segundo plano para que uma exportação grande não afete o sistema. Você pode continuar trabalhando enquanto isso.',
    'This only controls who sees this report. The data is always limited to what the person generating it is allowed to see.' => 'Isto define apenas quem vê este relatório. Os dados são sempre limitados ao que quem gera tem permissão de ver.',
    'Only used when the report is visible for members of selected groups.' => 'Usado apenas quando o relatório é visível para membros dos grupos selecionados.',
    'Report queued. You will be notified when it is ready to download.' => 'Relatório na fila. Você será avisado quando estiver pronto para baixar.',
    'Could not queue the report.' => 'Não foi possível colocar o relatório na fila.',
    'Your custom report is ready to download.' => 'Seu relatório personalizado está pronto para baixar.',
    'Custom report generation failed.' => 'A geração do relatório personalizado falhou.',
    'You do not have permission to use custom reports.' => 'Você não tem permissão para usar relatórios personalizados.',
    'You do not have permission to share reports at this level.' => 'Você não tem permissão para compartilhar relatórios neste nível.',
    'Only the author of a report can change it.' => 'Apenas o autor do relatório pode alterá-lo.',
    'This report is not available for download.' => 'Este relatório não está disponível para download.',
    'At least one group is required to share a report with a group.' => 'Selecione pelo menos um grupo para compartilhar o relatório com um grupo.',
    'The report matches %s rows, which is above the limit of %s. Please narrow the filters.' => 'O relatório encontrou %s linhas, acima do limite de %s. Restrinja os filtros.',
    'Create and generate custom reports. Results always respect the group and object permissions of the user generating them.' => 'Criar e gerar relatórios personalizados. O resultado sempre respeita as permissões de grupo e de objeto de quem gera.',
    'Share Custom Report With Group' => 'Compartilhar Relatório Personalizado com Grupo',
    'Save custom reports visible to the members of a group.' => 'Salvar relatórios personalizados visíveis aos membros de um grupo.',
    'Share Custom Report Globally' => 'Compartilhar Relatório Personalizado Globalmente',
    'Save custom reports visible to every user who may use custom reports.' => 'Salvar relatórios personalizados visíveis a todos os usuários que podem usar relatórios personalizados.',
    'Custom report row limit' => 'Limite de linhas do relatório personalizado',
    'Maximum number of rows a single custom report may generate. Protects the server from an unfiltered report scanning the whole database.' => 'Número máximo de linhas que um relatório personalizado pode gerar. Protege o servidor de um relatório sem filtro varrer o banco inteiro.',
    'Delete expired custom report files.' => 'Excluir arquivos expirados de relatórios personalizados.',

    # Core Workflow (ver checks_core_workflow.rb). Estas são traduzidas no
    # servidor, porque o rótulo do campo é interpolado antes de a mensagem
    # chegar ao frontend — não sobraria msgid para casar aqui.
    'The value selected for "%s" is not allowed by the current workflow rules.' => 'O valor escolhido para "%s" não é permitido pelas regras do fluxo de trabalho atual.',
    'The field "%s" is required.' => 'O campo "%s" é obrigatório.',

    # Macro cujas ações o usuário não pode aplicar (ver can_perform_changes.rb).
    'None of the actions could be applied. You may not have permission to change the affected fields.' => 'Nenhuma das ações pôde ser aplicada. Você pode não ter permissão para alterar os campos envolvidos.',

    # Acesso somente leitura do cliente (ver TicketPolicy#customer_update_allowed?).
    'You only have read access to this ticket and cannot change it.' => 'Você tem acesso somente leitura a este ticket e não pode alterá-lo.',
    'Ticket modification by customers' => 'Alteração de tickets por clientes',
    'Group selection for Ticket modification' => 'Seleção de grupos para alteração de tickets',
    'Defines if a customer can modify their tickets (change attributes, rename them or add articles). If disabled, customers get read-only access to tickets.' => 'Define se o cliente pode alterar os próprios tickets (mudar atributos, renomear ou adicionar artigos). Se desativado, o cliente passa a ter acesso somente leitura.',
    'Defines groups in which a customer can modify their tickets. No selection means all groups are available.' => 'Define os grupos nos quais o cliente pode alterar os próprios tickets. Nenhuma seleção significa todos os grupos.',
  }.freeze

  class << self
    def apply
      return unless Locale.exists?(locale: LOCALE)

      upsert = Service::Translation::Upsert
      OVERRIDES.each do |source, target|
        upsert.new(locale: LOCALE, source: source, target: target).execute
      end
      Rails.logger.info "[TranslationOverridesPtBr] Aplicados #{OVERRIDES.size} overrides para #{LOCALE}"
    end
  end
end
