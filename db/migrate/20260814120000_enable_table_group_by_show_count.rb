# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: liga a contagem de tickets por agrupamento na visão geral.

class EnableTableGroupByShowCount < ActiveRecord::Migration[8.0]
  # Em instalação nova quem liga isso é db/seeds/ats_settings.rb, que não roda
  # de novo aqui. Esta migration existe para as instalações já em produção.
  def up
    return if !Setting.exists?(name: 'system_init_done')

    Setting.set('ui_table_group_by_show_count', true)
  end

  def down
    Setting.set('ui_table_group_by_show_count', false)
  end
end
