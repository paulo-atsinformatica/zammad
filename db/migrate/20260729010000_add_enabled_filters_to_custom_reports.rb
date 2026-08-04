# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: filtros habilitados no relatório personalizado.

class AddEnabledFiltersToCustomReports < ActiveRecord::Migration[8.0]
  def up
    return if column_exists?(:custom_reports, :enabled_filters)

    # Atributos que a tela de visualização oferece para o usuário filtrar na
    # hora. Separado de `condition`: aquele é o recorte fixo do relatório, este
    # define o que fica editável por quem visualiza.
    #
    # jsonb (e não text + store) porque é uma lista: a macro `store` do Zammad
    # converte Array em {} silenciosamente.
    add_column :custom_reports, :enabled_filters, :jsonb, null: false, default: []
  end

  def down
    remove_column :custom_reports, :enabled_filters, if_exists: true
  end
end
