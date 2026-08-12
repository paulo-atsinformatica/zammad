# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: "Grupo Econômico" não é uma tabela própria — é um
# agrupamento por valor repetido em Organization#grupoeconomico (campo
# customizado). Este controller só lê esse agrupamento, para alimentar a
# busca global e a tela de perfil do grupo.
class EconomicGroupsController < ApplicationController
  prepend_before_action { authentication_check }
  prepend_before_action :check_ticket_agent_permission

  # GET /api/v1/economic_groups/search?query=...
  #
  # Usado pela busca global: nomes de grupo econômico que batem com o texto
  # digitado, com quantas organizações cada um tem.
  def search
    query = params[:query].to_s.strip
    return render json: [] if query.blank?

    groups = Organization
      .where_or_cis(%i[grupoeconomico], "%#{SqlHelper.quote_like(query)}%")
      .where.not(grupoeconomico: [nil, ''])
      .group(:grupoeconomico)
      .reorder(:grupoeconomico)
      .limit(10)
      .count

    render json: groups.map { |name, count| { name: name, count: count } }
  end

  # GET /api/v1/economic_groups/show?name=...
  #
  # Usado pela tela de perfil do grupo: todas as organizações amarradas ao
  # mesmo valor de grupoeconomico.
  def show
    name = params[:name].to_s

    organizations = Organization
      .where(grupoeconomico: name)
      .reorder(:name)

    render json: {
      name:          name,
      organizations: organizations.map { |organization| { id: organization.id, name: organization.name, active: organization.active } },
    }
  end

  private

  def check_ticket_agent_permission
    return if current_user.permissions?('ticket.agent')

    render json: { error: __('You do not have permission to view economic groups.') }, status: :forbidden
  end
end
