# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TicketTimeTracking, type: :model do
  let(:user) { create(:agent) }
  let(:ticket) { create(:ticket, owner: user) }

  describe 'validations' do
    it 'requires started_at' do
      tracking = described_class.new(ticket: ticket, user: user, created_by_id: user.id, updated_by_id: user.id)
      expect(tracking).not_to be_valid
      expect(tracking.errors[:started_at]).to be_present
    end

    it 'prevents multiple active trackings per user' do
      create(:ticket_time_tracking, ticket: ticket, user: user, is_active: true, started_at: Time.zone.now, created_by_id: user.id, updated_by_id: user.id)
      second_tracking = build(:ticket_time_tracking, ticket: ticket, user: user, is_active: true, started_at: Time.zone.now, created_by_id: user.id, updated_by_id: user.id)

      expect(second_tracking).not_to be_valid
      expect(second_tracking.errors[:base]).to be_present
    end
  end

  describe '#pause!' do
    it 'pauses an active tracking' do
      tracking = create(:ticket_time_tracking, ticket: ticket, user: user, is_active: true, started_at: 10.minutes.ago, created_by_id: user.id, updated_by_id: user.id)
      tracking.pause!

      expect(tracking.paused_at).to be_present
      expect(tracking.paused?).to be true
    end
  end

  describe '#resume!' do
    it 'resumes a paused tracking' do
      tracking = create(:ticket_time_tracking, ticket: ticket, user: user, is_active: true, started_at: 10.minutes.ago, paused_at: 5.minutes.ago, created_by_id: user.id, updated_by_id: user.id)
      tracking.resume!

      expect(tracking.resumed_at).to be_present
      expect(tracking.paused?).to be false
    end
  end

  describe '#notify_clients_data_attributes' do
    # Clients derive the live total themselves by adding the elapsed time since
    # resumed_at/started_at on top of total_seconds. If total_seconds already
    # carried the running segment, the player would count it twice.
    it 'reports total_seconds as the persisted accumulator, not the live total' do
      tracking = create(:ticket_time_tracking, ticket: ticket, user: user, is_active: true, started_at: 10.minutes.ago, total_seconds: 30, created_by_id: user.id, updated_by_id: user.id)

      expect(tracking.notify_clients_data_attributes).to include(total_seconds: 30)
    end

    it 'exposes the live total separately as total_time_seconds' do
      tracking = create(:ticket_time_tracking, ticket: ticket, user: user, is_active: true, started_at: 10.minutes.ago, total_seconds: 30, created_by_id: user.id, updated_by_id: user.id)

      expect(tracking.notify_clients_data_attributes[:total_time_seconds]).to be > 30
    end

    it 'matches the raw attributes used by the REST responses' do
      tracking = create(:ticket_time_tracking, ticket: ticket, user: user, is_active: true, started_at: 10.minutes.ago, total_seconds: 30, created_by_id: user.id, updated_by_id: user.id)

      expect(tracking.notify_clients_data_attributes[:total_seconds])
        .to eq(tracking.attributes_with_association_ids['total_seconds'])
    end
  end
end




