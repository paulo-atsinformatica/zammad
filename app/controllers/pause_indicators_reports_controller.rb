# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class PauseIndicatorsReportsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def index
    cached = PauseIndicatorsCache.redis_available? ? PauseIndicatorsCache.report_get : nil

    if cached
      entries = cached[:entries] || []
      entries = filter_entries_by_user_ids(entries, params[:user_ids])
      response = {
        entries:     entries,
        agents:      cached[:agents] || [],
        can_control: current_user&.permissions?('user.pause_control'),
        pause_types: cached[:pause_types] || [],
      }
      render json: response, status: :ok
      return
    end

    users = User.joins(:roles)
                .where(roles: { id: eligible_role_ids })
                .where(users: { active: true })
                .distinct
                .includes(:roles)

    if params[:user_ids].present?
      ids = Array(params[:user_ids]).reject(&:blank?).map(&:to_i)
      users = users.where(id: ids) if ids.any?
    end

    user_list = users.to_a

    # Carrega sessões ativas em lote (substitui N chamadas exists? por 1 query)
    logged_in_ids = UserPauseSession.active
                                    .where(user_id: user_list.map(&:id))
                                    .pluck(:user_id)
                                    .to_set

    # Carrega pausas ativas com pause_type em lote (substitui N find_by + N eager load)
    active_pause_ids = user_list.map(&:current_pause_id).compact
    pauses_by_id     = UserPause.includes(:pause_type)
                                .where(id: active_pause_ids, ended_at: nil)
                                .index_by(&:id)

    entries = user_list.map do |user|
      logged_in    = logged_in_ids.include?(user.id)
      active_pause = user.current_pause_id ? pauses_by_id[user.current_pause_id] : nil
      in_pause     = user.current_state == 'pause' && active_pause.present?
      state        = user.current_state || 'offline'

      status = if !logged_in
                 __('Deslogado')
               elsif in_pause
                 __('Em pausa')
               elsif state == 'offline'
                 __('Offline')
               else
                 __('Online')
               end

      {
        user:             user.attributes_with_association_ids,
        status:           status,
        logged_in:        logged_in,
        in_pause:         in_pause,
        state:            state,
        pause_name:       active_pause&.pause_type&.name,
        pause_started_at: active_pause&.started_at&.iso8601,
        pause_type_color: active_pause&.pause_type&.color
      }
    end

    can_control = current_user&.permissions?('user.pause_control')

    response = {
      entries:     entries,
      agents:      agents_list,
      can_control: can_control,
      pause_types: pause_types_list,
    }

    # Cache payload completo (sem filtro) para próximas requisições após invalidação
    if params[:user_ids].blank?
      PauseIndicatorsCache.report_set(response.slice(:entries, :agents, :pause_types))
    end

    render json: response, status: :ok
  end

  private

  def filter_entries_by_user_ids(entries, user_ids_param)
    return entries if user_ids_param.blank?

    ids = Array(user_ids_param).reject(&:blank?).map(&:to_i)
    return entries if ids.empty?

    entries.select { |e| ids.include?(e.dig(:user, :id).to_i) }
  end

  def eligible_role_ids
    @eligible_role_ids ||= Role.joins(:permissions)
                               .where(permissions: { name: 'user.pause_control', active: true }, roles: { active: true })
                               .where.not(roles: { name: %w[Admin Customer] })
                               .pluck(:id)
  end

  def pause_types_list
    PauseType.active.ordered.map do |pt|
      { id: pt.id, name: pt.name, time_limit: pt.time_limit }
    end
  end

  def agents_list
    User.joins(:roles)
        .where(roles: { id: eligible_role_ids })
        .where(users: { active: true })
        .distinct
        .order(:firstname, :lastname)
        .map { |u| { id: u.id, name: "#{u.firstname} #{u.lastname}".strip.presence || u.login } }
  end

end
