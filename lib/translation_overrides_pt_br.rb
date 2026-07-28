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
