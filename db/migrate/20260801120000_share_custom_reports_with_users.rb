# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: compartilhamento do relatório personalizado.

class ShareCustomReportsWithUsers < ActiveRecord::Migration[8.0]
  # O relatório deixa de ter "nível de visibilidade" e passa a ser compartilhado
  # como a Visão Geral: por grupos e/ou por usuários escolhidos.
  #
  # Quem criou sempre enxerga o próprio relatório, então "pessoal" vira
  # simplesmente um relatório sem grupo nem usuário adicional.
  def up
    create_join_table :custom_reports, :users do |t|
      t.index %i[custom_report_id user_id], unique: true, name: 'index_custom_reports_users'
    end

    return if !Setting.exists?(name: 'system_init_done')

    convert_personal_reports
  end

  def down
    drop_table :custom_reports_users, if_exists: true
  end

  private

  # 'personal' passa a ser o relatório sem compartilhamento nenhum: já era
  # visível só para o autor, e continua sendo por `created_by_id`. Nada a fazer
  # além de registrar que a coluna `visibility` deixou de ser consultada.
  #
  # 'group' já tem os grupos ligados e segue valendo.
  #
  # A coluna `visibility` é mantida de propósito: remover agora impediria voltar
  # atrás sem perder informação, e ela não é mais lida em lugar nenhum.
  def convert_personal_reports
    say "custom_reports por visibilidade: #{CustomReport.group(:visibility).count}"
  end
end
