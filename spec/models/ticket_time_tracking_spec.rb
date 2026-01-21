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
end




