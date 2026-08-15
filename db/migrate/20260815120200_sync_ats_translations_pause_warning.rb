# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: traduções pt-BR das customizações.

class SyncAtsTranslationsPauseWarning < ActiveRecord::Migration[8.0]
  # Cada lote de strings novas em i18n/ats.pt-br.po precisa da própria migration:
  # migration roda uma única vez, então a anterior não reimporta o que veio
  # depois dela. Em instalação nova quem importa é db/seeds.rb.
  def up
    return if !Setting.exists?(name: 'system_init_done')

    Translation.sync_locale_from_po('pt-br')
  end

  def down
    # Nada a desfazer: remover as traduções deixaria as telas em inglês sem ganho.
  end
end
