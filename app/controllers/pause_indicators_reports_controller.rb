# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class PauseIndicatorsReportsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def index
    agent_role_ids = Role.joins(:permissions)
                         .where(permissions: { name: 'ticket.agent', active: true }, roles: { active: true })
                         .pluck(:id)

    users = User.joins(:roles)
                .where(roles: { id: agent_role_ids })
                .where(users: { active: true })
                .distinct
                .includes(:roles)

    entries = users.map do |user|
      logged_in = UserPauseSession.active.exists?(user_id: user.id)
      in_pause = user.in_pause?
      state = user.current_state || 'offline'

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
        pause_name: user.active_pause&.pause_type&.name
      }
    end

    render json: { entries: entries }, status: :ok
  end
end
