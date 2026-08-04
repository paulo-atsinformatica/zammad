# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :ticket_time_tracking do
    association :ticket
    association :user
    started_at { Time.zone.now }
    is_active { true }
    total_seconds { 0 }
    created_by_id { 1 }
    updated_by_id { 1 }
  end
end




