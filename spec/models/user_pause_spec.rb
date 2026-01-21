# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe UserPause, type: :model do
  let(:user) { create(:agent) }
  let(:pause_type) { create(:pause_type, time_limit: 30, created_by_id: user.id, updated_by_id: user.id) }

  describe 'validations' do
    it 'requires started_at' do
      user_pause = described_class.new(user: user, time_limit: 30, created_by_id: user.id, updated_by_id: user.id)
      expect(user_pause).not_to be_valid
      expect(user_pause.errors[:started_at]).to be_present
    end
  end

  describe '#active?' do
    it 'returns true when ended_at is nil' do
      user_pause = create(:user_pause, user: user, started_at: Time.zone.now, ended_at: nil, created_by_id: user.id, updated_by_id: user.id)
      expect(user_pause.active?).to be true
    end

    it 'returns false when ended_at is present' do
      user_pause = create(:user_pause, user: user, started_at: 1.hour.ago, ended_at: Time.zone.now, created_by_id: user.id, updated_by_id: user.id)
      expect(user_pause.active?).to be false
    end
  end

  describe '#exceeded_time_limit?' do
    it 'returns true when time limit is exceeded' do
      user_pause = create(:user_pause, user: user, pause_type: pause_type, started_at: 31.minutes.ago, time_limit: 30, created_by_id: user.id, updated_by_id: user.id)
      expect(user_pause.exceeded_time_limit?).to be true
    end

    it 'returns false when time limit is not exceeded' do
      user_pause = create(:user_pause, user: user, pause_type: pause_type, started_at: 10.minutes.ago, time_limit: 30, created_by_id: user.id, updated_by_id: user.id)
      expect(user_pause.exceeded_time_limit?).to be false
    end
  end
end




