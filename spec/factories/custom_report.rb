# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: relatório personalizado.

FactoryBot.define do
  factory :custom_report do
    sequence(:name) { |n| "Relatório #{n}" }
    object          { 'Ticket' }
    visibility      { 'personal' }
    condition       { {} }
    columns         { [] }
    group_by        { [] }
    aggregations    { [] }
    active          { true }
    created_by_id   { 1 }
    updated_by_id   { 1 }

    factory :custom_report_global do
      visibility { 'global' }
    end
  end

  factory :custom_report_run do
    custom_report
    format        { 'csv' }
    status        { 'pending' }
    created_by_id { 1 }
    updated_by_id { 1 }
  end
end
