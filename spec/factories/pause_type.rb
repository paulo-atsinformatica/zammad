# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

FactoryBot.define do
  factory :pause_type do
    name { 'Almoço' }
    time_limit { 60 }
    color { '#FFA500' }
    active { true }
    created_by_id { 1 }
    updated_by_id { 1 }
  end
end




