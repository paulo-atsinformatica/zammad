# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: relatório personalizado.

FactoryBot.define do
  factory :custom_report do
    sequence(:name) { |n| "Relatório #{n}" }
    object          { 'Ticket' }
    visibility      { 'personal' }
    condition       { {} }
    columns                { [] }
    group_by               { [] }
    aggregations           { [] }
    aggregation_attributes { [] }
    active          { true }
    created_by_id   { 1 }
    updated_by_id   { 1 }

    # "Geral": visível para quem tem acesso a algum dos grupos escolhidos. Não
    # existe mais nível global — para valer para todos, escolhem-se todos os
    # grupos.
    factory :custom_report_general do
      visibility { 'group' }
      groups { [Group.first || create(:group)] }
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
