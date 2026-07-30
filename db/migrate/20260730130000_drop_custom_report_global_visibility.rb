# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: relatório personalizado.

class DropCustomReportGlobalVisibility < ActiveRecord::Migration[8.0]
  # O nível 'global' saiu: sobram 'personal' e 'group' ("Geral"). Para um
  # relatório valer para todo mundo basta escolher todos os grupos, então um nível
  # à parte só acrescentava uma permissão para conceder o mesmo resultado por
  # outro caminho.
  #
  # Os relatórios que eram globais viram 'group' com todos os grupos anexados,
  # que é o equivalente exato — assim ninguém perde acesso a um relatório que já
  # usava.
  def up
    return if !Setting.exists?(name: 'system_init_done')

    convert_global_reports
    Permission.where(name: 'report.custom.global').destroy_all
  end

  def down
    # Nada a desfazer: recriar a permissão não devolveria a visibilidade antiga
    # dos relatórios, que já foi convertida para o equivalente.
  end

  private

  def convert_global_reports
    group_ids = Group.pluck(:id)

    CustomReport.where(visibility: 'global').find_each do |report|
      report.group_ids = group_ids
      report.update_columns(visibility: 'group') # rubocop:disable Rails/SkipsModelValidations
    end
  end
end
