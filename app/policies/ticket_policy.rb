# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class TicketPolicy < ApplicationPolicy

  def show?
    access?('read')
  end

  def create?
    return false if !ensure_group?

    access?('create')
  end

  def update?
    change_access?
  end

  def destroy?
    return true if user.permissions?('admin')

    # This might look like a bug is actually just defining
    # what exception is being raised and shown to the user.
    return false if !access?('delete')

    not_authorized('admin permission required')
  end

  def full?
    access?('full')
  end

  def ensure_group?
    return true if record.group_id

    not_authorized Exceptions::UnprocessableContent.new __("The required value 'group_id' is missing.")
  end

  def follow_up?
    # This method is used to check if a follow-up is possible (mostly based on the configuration).
    # Agents are always allowed to reopen tickets, configuration does not matter.

    return update? if Ticket::StateType.lookup(id: record.state.state_type_id).name != 'closed' # check if the ticket state is already closed
    return true if agent_update_access?

    # Check follow_up_possible configuration, based on the group.
    return true if follow_up_possible? && update?

    not_authorized Exceptions::UnprocessableContent.new __('Cannot follow-up on a closed ticket. Please create a new ticket.')
  end

  def agent_read_access?
    agent_access?('read')
  end

  def agent_update_access?
    agent_access?('change')
  end

  def agent_create_access?
    agent_access?('create')
  end

  def create_mentions?
    return true if agent_read_access?

    not_authorized __('You have insufficient permissions to mention other users.')
  end

  private

  def follow_up_possible?
    case record.group.follow_up_possible
    when 'yes'
      true
    when 'new_ticket_after_certain_time'
      record.reopen_after_certain_time?
    when 'new_ticket'
      false
    end
  end

  def access?(access)
    return true if agent_access?(access)

    customer_access?
  end

  def change_access?
    # Update permission needs an special handling related to ticket.agent+ticket.customer
    # situation, because agenr read permission should win over the general customer permission.
    return true if agent_update_access?
    return false if agent_read_access?

    # Customização ATS: permite dar acesso somente leitura ao cliente.
    # Restrito a quem tem a permissão de cliente para não devolver essa
    # mensagem a quem não tem acesso nenhum ao ticket.
    return read_only_for_customer if user.permissions?('ticket.customer') && !customer_update_allowed?

    customer_access?
  end

  def agent_access?(access)
    return false if !user.permissions?('ticket.agent')

    user.group_access?(record.group.id, access)
  end

  def customer_access?
    return false if !user.permissions?('ticket.customer')
    return customer_field_scope if customer?

    shared_organization?
  end

  def customer?
    record.customer_id == user.id
  end

  def shared_organization?
    return false if record.organization_id.blank?
    return false if user.organization_id.blank?
    return false if !user.organization_id?(record.organization_id)
    return false if !record.organization.shared?

    customer_field_scope
  end

  def customer_field_scope
    @customer_field_scope ||= ApplicationPolicy::FieldScope.new(deny: %i[ai_agent_running ai_summary_enabled time_unit time_units_per_type checklist referencing_checklist_tickets ai_stored_results])
  end

  # Customização ATS: acesso somente leitura ao ticket para o cliente,
  # opcionalmente restrito a grupos.
  #
  # Só é consultado a partir de change_access?, então leitura permanece
  # liberada. Como update_title e a criação de artigo (via follow_up?) também
  # passam por update?, isto cobre renomear e comentar além dos atributos.
  def customer_update_allowed?
    setting = Setting.get('customer_ticket_update')

    # Ausência do setting (instalação em que a migration ainda não rodou)
    # mantém o comportamento anterior, em que o cliente altera o próprio
    # ticket. Só bloqueia quando explicitamente configurado.
    return true if setting.nil?
    return false if !setting

    # Mesma semântica de customer_ticket_create_group_ids: a lista estreita a
    # permissão, e nenhuma seleção significa todos os grupos.
    group_ids = Setting.get('customer_ticket_update_group_ids')
    return true if group_ids.blank?

    Array.wrap(group_ids).map(&:to_s).include?(record.group_id.to_s)
  end

  def read_only_for_customer
    not_authorized Exceptions::Forbidden.new __('You only have read access to this ticket and cannot change it.')
  end
end
