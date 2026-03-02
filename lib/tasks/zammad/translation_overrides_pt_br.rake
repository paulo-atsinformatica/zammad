# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# ATS: aplica overrides de tradução pt-BR (como se feitos pela interface).

namespace :zammad do
  desc 'Apply pt-BR translation overrides (customizations stored in DB, not in .po)'
  task translation_overrides_pt_br: :environment do
    require Rails.root.join('lib', 'translation_overrides_pt_br')
    TranslationOverridesPtBr.apply
    puts 'pt-BR overrides applied.'
  end
end
