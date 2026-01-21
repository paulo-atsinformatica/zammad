# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe PauseType, type: :model do
  let(:user) { create(:admin) }

  describe 'validations' do
    it 'requires name' do
      pause_type = described_class.new(time_limit: 30, created_by_id: user.id, updated_by_id: user.id)
      expect(pause_type).not_to be_valid
      expect(pause_type.errors[:name]).to be_present
    end

    it 'requires time_limit greater than 0' do
      pause_type = described_class.new(name: 'Test', time_limit: 0, created_by_id: user.id, updated_by_id: user.id)
      expect(pause_type).not_to be_valid
      expect(pause_type.errors[:time_limit]).to be_present
    end

    it 'validates color format' do
      pause_type = described_class.new(name: 'Test', time_limit: 30, color: 'invalid', created_by_id: user.id, updated_by_id: user.id)
      expect(pause_type).not_to be_valid
      expect(pause_type.errors[:color]).to be_present
    end
  end

  describe 'scopes' do
    it 'returns only active pause types' do
      active = create(:pause_type, active: true, created_by_id: user.id, updated_by_id: user.id)
      inactive = create(:pause_type, active: false, created_by_id: user.id, updated_by_id: user.id)

      expect(described_class.active).to include(active)
      expect(described_class.active).not_to include(inactive)
    end
  end
end




