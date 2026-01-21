# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class TicketTimeTrackingsReportsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  def index
    open_start_date = params[:open_start_date].present? ? Date.parse(params[:open_start_date]) : 30.days.ago.to_date
    open_end_date = params[:open_end_date].present? ? Date.parse(params[:open_end_date]) : Date.today
    close_start_date = params[:close_start_date].present? ? Date.parse(params[:close_start_date]) : nil
    close_end_date = params[:close_end_date].present? ? Date.parse(params[:close_end_date]) : nil
    ticket_query = params[:ticket_query].presence
    agent_query = params[:agent_query].presence

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

    if agent_query
      like = "%#{agent_query}%"
      trackings = trackings.joins(:user)
                           .where('users.firstname ILIKE ? OR users.lastname ILIKE ? OR users.email ILIKE ?', like, like, like)
    end

    entries = trackings.order(started_at: :desc).map do |tracking|
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
        current_state: ticket.state&.name
      }
    end

    render json: {
      open_start_date: open_start_date,
      open_end_date: open_end_date,
      close_start_date: close_start_date,
      close_end_date: close_end_date,
      entries: entries
    }, status: :ok
  end
end

