# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: relatório personalizado.

FactoryBot.define do
  factory :custom_report do
    sequence(:name) { |n| "Relatório #{n}" }
    object                 { 'Ticket' }
    condition              { {} }
    columns                { [] }
    group_by               { [] }
    aggregations           { [] }
    aggregation_attributes { [] }
    active                 { true }
    created_by_id          { 1 }
    updated_by_id          { 1 }

    # Compartilhado com um grupo. Sem grupo nem usuário, o relatório só é visto
    # por quem o criou — o equivalente ao antigo "pessoal".
    factory :custom_report_shared do
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
