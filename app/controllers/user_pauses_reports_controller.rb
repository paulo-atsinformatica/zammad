# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class UserPausesReportsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def index
    start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : 30.days.ago.to_date
    end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.today
    pause_type_id = params[:pause_type_id].presence
    exceeded_filter = params[:exceeded].presence
    agent_id = params[:agent_id].presence
    agent_query = params[:agent_query].presence

    user_scope = User.all
    if agent_id
      user_scope = user_scope.where(id: agent_id)
    elsif agent_query
      like = "%#{agent_query}%"
      user_scope = user_scope.where(
        'firstname ILIKE ? OR lastname ILIKE ? OR email ILIKE ?',
        like, like, like
      )
    end

    if equipe_column? && params[:equipe].present?
      teams = Array(params[:equipe]).reject(&:blank?)
      user_scope = user_scope.where(equipe: teams) if teams.any?
    end

    user_ids = user_scope.select(:id)

    pauses_scope = UserPause.where(started_at: start_date.beginning_of_day..end_date.end_of_day)
                            .includes(:user, :pause_type)
    sessions_scope = UserPauseSession.where(started_at: start_date.beginning_of_day..end_date.end_of_day)
                                     .includes(:user)

    pauses_scope = pauses_scope.where(user_id: user_ids) if agent_id || agent_query
    sessions_scope = sessions_scope.where(user_id: user_ids) if agent_id || agent_query

    if pause_type_id == 'login_logout'
      pauses_scope = pauses_scope.none
    elsif pause_type_id.present? && pause_type_id != 'all'
      pauses_scope = pauses_scope.where(pause_type_id: pause_type_id)
      sessions_scope = sessions_scope.none
    end

    entries = []

    pauses_scope.find_each do |pause|
      duration_minutes = pause.duration_minutes
      exceeded = pause.time_limit.to_i.positive? && duration_minutes > pause.time_limit
      entries << {
        type: 'pause',
        name: pause.pause_type&.name || __('Pausa'),
        agent: pause.user.attributes_with_association_ids,
        started_at: pause.started_at,
        ended_at: pause.ended_at,
        time_limit: pause.time_limit,
        duration_seconds: pause.duration_seconds,
        exceeded: exceeded
      }
    end

    sessions_scope.find_each do |session|
      entries << {
        type: 'login_logout',
        name: __('Login/Logout'),
        agent: session.user.attributes_with_association_ids,
        started_at: session.started_at,
        ended_at: session.ended_at,
        time_limit: nil,
        duration_seconds: session.duration_seconds,
        exceeded: false
      }
    end

    if exceeded_filter == 'yes'
      entries.select! { |item| item[:exceeded] }
    elsif exceeded_filter == 'no'
      entries.select! { |item| !item[:exceeded] }
    end

    entries.sort_by! { |item| item[:started_at] || Time.zone.at(0) }.reverse!

    response = {
      start_date: start_date,
      end_date: end_date,
      entries: entries
    }
    response[:teams] = teams_list if equipe_column?

    render json: response, status: :ok
  end

  private

  def equipe_column?
    @equipe_column ||= User.column_names.include?('equipe')
  end

  def teams_list
    agent_role_ids = Role.joins(:permissions)
                         .where(permissions: { name: 'ticket.agent', active: true }, roles: { active: true })
                         .pluck(:id)

    User.joins(:roles)
        .where(roles: { id: agent_role_ids })
        .where(users: { active: true })
        .where.not(equipe: [nil, ''])
        .distinct
        .pluck(:equipe)
        .compact
        .sort
  end
end




