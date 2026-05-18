# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class UserPausesReportsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def index
    start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : 30.days.ago.to_date
    end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.today
    page = [1, (params[:page].presence || 1).to_i].max
    per_page = [[1, (params[:per_page].presence || 50).to_i].max, 100].min

    entries = build_entries_for_report
    total_count = entries.size
    total_pages = (total_count.to_f / per_page).ceil
    page = total_pages if page > total_pages && total_pages > 0
    offset = (page - 1) * per_page
    entries = entries.slice(offset, per_page) || []

    response = {
      start_date: start_date,
      end_date: end_date,
      entries: entries,
      agents: agents_list,
      teams: teams_list,
      pagination: {
        page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: total_pages
      }
    }

    render json: response, status: :ok
  end

  # GET /api/v1/reports/user_pauses/download?start_date=...&end_date=... (same filters as index)
  def download
    entries = build_entries_for_report
    header = [
      { display: __('Responsável'), width: 22 },
      { display: __('Nome da Pausa'), width: 20 },
      { display: __('Data'), width: 12 },
      { display: __('Hora Início'), width: 12 },
      { display: __('Hora Fim'), width: 12 },
      { display: __('Tempo Máximo'), width: 14 },
      { display: __('Duração Total'), width: 14 },
      { display: __('Tempo excedido'), width: 12 },
      { display: __('Motivo do atraso'), width: 24 }
    ]
    records = entries.map do |item|
      agent_name = item[:agent].present? ? "#{item[:agent]['firstname']} #{item[:agent]['lastname']}".strip : ''
      [
        agent_name,
        item[:name],
        item[:started_at]&.in_time_zone(timezone_default).strftime('%Y-%m-%d'),
        format_time_with_seconds(item[:started_at]),
        format_time_with_seconds(item[:ended_at]),
        item[:time_limit].present? ? format_duration_from_minutes(item[:time_limit]) : '-',
        format_duration_from_seconds(item[:duration_seconds]),
        item[:exceeded] ? __('Sim') : __('Não'),
        item[:delay_reason].to_s.presence || '-'
      ]
    end
    excel = ExcelSheet.new(
      title:    __('Relatório de Pausas de Usuários'),
      header:   header,
      records:  records,
      timezone: timezone_default,
      locale:   current_user.locale
    )
    filename = "pausas-usuarios-#{params[:start_date]}-#{params[:end_date]}.xlsx"
    send_data(
      excel.content,
      filename:    filename,
      type:        ExcelSheet::CONTENT_TYPE,
      disposition: 'attachment'
    )
  end

  private

  def timezone_default
    Setting.get('timezone_default') || 'UTC'
  end

  def format_time_with_seconds(t)
    return '' if t.blank?
    t.in_time_zone(timezone_default).strftime('%H:%M:%S')
  end

  def format_duration_from_seconds(sec)
    return '' if sec.nil? || sec < 0
    h = sec / 3600
    m = (sec % 3600) / 60
    s = sec % 60
    format('%d:%02d:%02d', h, m, s)
  end

  def format_duration_from_minutes(minutes)
    format_duration_from_seconds((minutes.to_i) * 60)
  end

  def build_entries_for_report
    start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : 30.days.ago.to_date
    end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.today
    pause_type_id = params[:pause_type_id].presence
    exceeded_filter = params[:exceeded].presence
    agent_id = params[:agent_id].presence
    agent_query = params[:agent_query].presence

    equipe_filter = params[:equipe].presence

    user_scope = User.all
    if equipe_filter.present? && User.column_names.include?('equipe')
      user_scope = user_scope.where(equipe: equipe_filter)
    end
    if agent_id.present?
      user_scope = user_scope.where(id: agent_id)
    elsif agent_query.present?
      like = "%#{agent_query}%"
      user_scope = user_scope.where(
        'firstname ILIKE ? OR lastname ILIKE ? OR email ILIKE ?',
        like, like, like
      )
    end
    user_ids = user_scope.select(:id)

    pauses_scope = UserPause.where(started_at: start_date.beginning_of_day..end_date.end_of_day)
                            .includes(:user, :pause_type)
    sessions_scope = UserPauseSession.where(started_at: start_date.beginning_of_day..end_date.end_of_day)
                                     .includes(:user)
    filter_users = agent_id.present? || agent_query.present? || equipe_filter.present?
    pauses_scope = pauses_scope.where(user_id: user_ids) if filter_users
    sessions_scope = sessions_scope.where(user_id: user_ids) if filter_users

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
        exceeded: exceeded,
        delay_reason: pause.delay_reason
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
        exceeded: false,
        delay_reason: nil
      }
    end

    if exceeded_filter == 'yes'
      entries.select! { |item| item[:exceeded] }
    elsif exceeded_filter == 'no'
      entries.select! { |item| !item[:exceeded] }
    end
    entries.sort_by! { |item| item[:started_at] || Time.zone.at(0) }.reverse!
    entries
  end

  def agents_list
    eligible_ids = Role.joins(:permissions)
                       .where(permissions: { name: 'user.pause_control', active: true }, roles: { active: true })
                       .where.not(roles: { name: %w[Admin Customer] })
                       .pluck(:id)

    User.joins(:roles)
        .where(roles: { id: eligible_ids })
        .where(users: { active: true })
        .distinct
        .order(:firstname, :lastname)
        .map { |u| { id: u.id, name: "#{u.firstname} #{u.lastname}".strip } }
  end

  def teams_list
    return [] unless User.column_names.include?('equipe')

    eligible_ids = Role.joins(:permissions)
                       .where(permissions: { name: 'user.pause_control', active: true }, roles: { active: true })
                       .where.not(roles: { name: %w[Admin Customer] })
                       .pluck(:id)

    User.joins(:roles)
        .where(roles: { id: eligible_ids })
        .where(users: { active: true })
        .where.not(equipe: [nil, ''])
        .distinct
        .order(:equipe)
        .pluck(:equipe)
  end
end




