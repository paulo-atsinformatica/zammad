# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class PauseIndicatorsReportsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def index
    users = User.joins(:roles)
                .where(roles: { id: eligible_role_ids })
                .where(users: { active: true })
                .distinct
                .includes(:roles)

    if params[:user_ids].present?
      ids = Array(params[:user_ids]).reject(&:blank?).map(&:to_i)
      users = users.where(id: ids) if ids.any?
    end

    entries = users.map do |user|
      logged_in = UserPauseSession.active.exists?(user_id: user.id)
      in_pause = user.in_pause?
      state = user.current_state || 'offline'
      active_pause = user.active_pause

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
        user: user.attributes_with_association_ids,
        status: status,
        logged_in: logged_in,
        in_pause: in_pause,
        state: state,
        pause_name: active_pause&.pause_type&.name,
        pause_started_at: active_pause&.started_at&.iso8601,
        pause_type_color: active_pause&.pause_type&.color
      }
    end

    response = { entries: entries, agents: agents_list }

    render json: response, status: :ok
  end

  private

  def eligible_role_ids
    @eligible_role_ids ||= Role.joins(:permissions)
                               .where(permissions: { name: 'user.pause_control', active: true }, roles: { active: true })
                               .where.not(roles: { name: %w[Admin Customer] })
                               .pluck(:id)
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
