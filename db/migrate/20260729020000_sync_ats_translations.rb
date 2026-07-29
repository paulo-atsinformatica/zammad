# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: traduções pt-BR das customizações.

class SyncAtsTranslations < ActiveRecord::Migration[8.0]
  # Em instalação nova quem importa i18n/ats.pt-br.po é db/seeds.rb, que já roda
  # Translation.sync. Esta migration existe para as instalações já em produção,
  # onde os seeds não voltam a rodar.
  def up
    return if !Setting.exists?(name: 'system_init_done')

    # Só pt-br: é o único locale com arquivo ATS, e sincronizar todos os locales
    # levaria minutos sem benefício.
    Translation.sync_locale_from_po('pt-br')
  end

  def down
    # Nada a desfazer: remover as traduções deixaria as telas em inglês sem
    # ganho nenhum.
  end
end
