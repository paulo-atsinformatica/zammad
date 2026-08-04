# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :user_pause do
    association :user
    association :pause_type, factory: :pause_type
    started_at { Time.zone.now }
    time_limit { 30 }
    created_by_id { 1 }
    updated_by_id { 1 }
  end
end




