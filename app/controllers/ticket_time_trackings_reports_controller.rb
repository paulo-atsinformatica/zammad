# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class TicketTimeTrackingsReportsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def index
    open_start_date = params[:open_start_date].present? ? Date.parse(params[:open_start_date]) : 30.days.ago.to_date
    open_end_date = params[:open_end_date].present? ? Date.parse(params[:open_end_date]) : Date.today
    close_start_date = params[:close_start_date].present? ? Date.parse(params[:close_start_date]) : nil
    close_end_date = params[:close_end_date].present? ? Date.parse(params[:close_end_date]) : nil
    ticket_query = params[:ticket_query].presence
    agent_id = params[:agent_id].presence
    agent_query = params[:agent_query].presence
    page = [1, (params[:page].presence || 1).to_i].max
    per_page = [[1, (params[:per_page].presence || 50).to_i].max, 100].min

    trackings = TicketTimeTracking.joins(:ticket)
                                   .includes(:user, ticket: :state)

    trackings = trackings.where(tickets: { created_at: open_start_date.beginning_of_day..open_end_date.end_of_day })

    if close_start_date && close_end_date
      trackings = trackings.where(tickets: { close_at: close_start_date.beginning_of_day..close_end_date.end_of_day })
    elsif close_start_date
      trackings = trackings.where('tickets.close_at >= ?', close_start_date.beginning_of_day)
    elsif close_end_date
      trackings = trackings.where('tickets.close_at <= ?', close_end_date.end_of_day)
    end

    if ticket_query
      like = "%#{ticket_query}%"
      trackings = trackings.where('tickets.number ILIKE ? OR tickets.title ILIKE ?', like, like)
    end

    if agent_id
      trackings = trackings.where(user_id: agent_id)
    elsif agent_query
      like = "%#{agent_query}%"
      trackings = trackings.joins(:user)
                           .where('users.firstname ILIKE ? OR users.lastname ILIKE ? OR users.email ILIKE ?', like, like, like)
    end

    total_count = trackings.count
    total_pages = (total_count.to_f / per_page).ceil
    page = total_pages if page > total_pages && total_pages > 0
    offset = (page - 1) * per_page

    trackings = trackings.order(started_at: :desc).limit(per_page).offset(offset)

    entries = trackings.map do |tracking|
      ticket = tracking.ticket
      user = tracking.user
      end_time = tracking.ended_at || tracking.paused_at
      duration_seconds = if tracking.started_at
                           end_point = end_time || Time.zone.now
                           (end_point - tracking.started_at).to_i
                         else
                           0
                         end
      total_seconds = tracking.total_time_seconds
      paused_seconds = [duration_seconds - total_seconds, 0].max

      {
        ticket: ticket.attributes_with_association_ids,
        user: user.attributes_with_association_ids,
        opened_at: ticket.created_at,
        closed_at: ticket.close_at,
        started_at: tracking.started_at,
        ended_at: end_time,
        paused_seconds: paused_seconds,
        total_seconds: total_seconds,
        current_state: ticket.state ? translate_state_name(ticket.state) : nil
      }
    end

    response = {
      open_start_date: open_start_date,
      open_end_date: open_end_date,
      close_start_date: close_start_date,
      close_end_date: close_end_date,
      entries: entries,
      agents: agents_list,
      pagination: {
        page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: total_pages
      }
    }

    render json: response, status: :ok
  end

  # GET /api/v1/reports/ticket_time_trackings/download (same query params as index)
  def download
    entries = build_entries_for_report
    header = [
      { display: __('Ticket'), width: 28 },
      { display: __('Responsável'), width: 22 },
      { display: __('Data de abertura'), width: 14 },
      { display: __('Data de fechamento'), width: 16 },
      { display: __('Data/Hora de início'), width: 18 },
      { display: __('Data/Hora de término'), width: 18 },
      { display: __('Tempo total de atendimento'), width: 22 },
      { display: __('Tempo do atendimento pausado'), width: 26 },
      { display: __('Estado atual'), width: 16 }
    ]
    tz = timezone_default
    records = entries.map do |item|
      ticket = item[:ticket]
      ticket_label = ticket.present? ? "##{ticket['number']} - #{ticket['title']}" : ''
      user = item[:user]
      user_name = user.present? ? "#{user['firstname']} #{user['lastname']}".strip : ''
      [
        ticket_label,
        user_name,
        item[:opened_at]&.in_time_zone(tz).strftime('%Y-%m-%d'),
        item[:closed_at]&.in_time_zone(tz).strftime('%Y-%m-%d'),
        item[:started_at]&.in_time_zone(tz).strftime('%Y-%m-%d %H:%M:%S'),
        item[:ended_at]&.in_time_zone(tz).strftime('%Y-%m-%d %H:%M:%S'),
        format_duration_from_seconds(item[:total_seconds]),
        format_duration_from_seconds(item[:paused_seconds]),
        item[:current_state].to_s
      ]
    end
    excel = ExcelSheet.new(
      title:    __('Relatório de Tempo de Atendimento'),
      header:   header,
      records:  records,
      timezone: tz,
      locale:   current_user.locale
    )
    filename = "tempo-atendimento-#{params[:open_start_date]}-#{params[:open_end_date]}.xlsx"
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

  def format_duration_from_seconds(sec)
    return '' if sec.nil? || sec < 0
    h = sec / 3600
    m = (sec % 3600) / 60
    s = sec % 60
    format('%d:%02d:%02d', h, m, s)
  end

  def build_entries_for_report
    open_start_date = params[:open_start_date].present? ? Date.parse(params[:open_start_date]) : 30.days.ago.to_date
    open_end_date = params[:open_end_date].present? ? Date.parse(params[:open_end_date]) : Date.today
    close_start_date = params[:close_start_date].present? ? Date.parse(params[:close_start_date]) : nil
    close_end_date = params[:close_end_date].present? ? Date.parse(params[:close_end_date]) : nil
    ticket_query = params[:ticket_query].presence
    agent_id = params[:agent_id].presence
    agent_query = params[:agent_query].presence

    trackings = TicketTimeTracking.joins(:ticket)
                                  .includes(:user, ticket: :state)
                                  .where(tickets: { created_at: open_start_date.beginning_of_day..open_end_date.end_of_day })

    if close_start_date && close_end_date
      trackings = trackings.where(tickets: { close_at: close_start_date.beginning_of_day..close_end_date.end_of_day })
    elsif close_start_date
      trackings = trackings.where('tickets.close_at >= ?', close_start_date.beginning_of_day)
    elsif close_end_date
      trackings = trackings.where('tickets.close_at <= ?', close_end_date.end_of_day)
    end

    if ticket_query.present?
      like = "%#{ticket_query}%"
      trackings = trackings.where('tickets.number ILIKE ? OR tickets.title ILIKE ?', like, like)
    end

    if agent_id.present?
      trackings = trackings.where(user_id: agent_id)
    elsif agent_query.present?
      like = "%#{agent_query}%"
      trackings = trackings.joins(:user)
                           .where('users.firstname ILIKE ? OR users.lastname ILIKE ? OR users.email ILIKE ?', like, like, like)
    end

    trackings.order(started_at: :desc).map do |tracking|
      ticket = tracking.ticket
      user = tracking.user
      end_time = tracking.ended_at || tracking.paused_at
      duration_seconds = if tracking.started_at
                           end_point = end_time || Time.zone.now
                           (end_point - tracking.started_at).to_i
                         else
                           0
                         end
      total_seconds = tracking.total_time_seconds
      paused_seconds = [duration_seconds - total_seconds, 0].max
      {
        ticket: ticket.attributes_with_association_ids,
        user: user.attributes_with_association_ids,
        opened_at: ticket.created_at,
        closed_at: ticket.close_at,
        started_at: tracking.started_at,
        ended_at: end_time,
        paused_seconds: paused_seconds,
        total_seconds: total_seconds,
        current_state: ticket.state ? translate_state_name(ticket.state) : nil
      }
    end
  end

  def translate_state_name(state)
    return nil if state.blank?

    locale = current_user.locale&.downcase
    translated = Translation.translate(locale, state.name)
    return translated if translated != state.name

    # Fallback em português para locale pt-* quando não houver tradução no banco
    return STATE_NAME_PT_BR[state.name] || state.name if locale&.start_with?('pt')

    state.name
  end

  STATE_NAME_PT_BR = {
    'new'               => 'Novo',
    'open'              => 'Aberto',
    'closed'            => 'Fechado',
    'merged'            => 'Mesclado',
    'removed'           => 'Removido',
    'pending reminder'  => 'Lembrete pendente',
    'pending action'    => 'Ação pendente',
    'pending close'     => 'Fechamento pendente'
  }.freeze

  def agents_list
    agent_role_ids = Role.joins(:permissions)
                         .where(permissions: { name: 'ticket.agent', active: true }, roles: { active: true })
                         .pluck(:id)

    User.joins(:roles)
        .where(roles: { id: agent_role_ids })
        .where(users: { active: true })
        .distinct
        .order(:firstname, :lastname)
        .map { |u| { id: u.id, name: "#{u.firstname} #{u.lastname}".strip } }
  end
end

