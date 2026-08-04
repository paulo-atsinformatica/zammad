# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: execuções (gerações) de um relatório personalizado.

class CreateCustomReportRuns < ActiveRecord::Migration[8.0]
  # Ver CreateCustomReports: up/down explícitos porque a reversão automática
  # tropeça ao remover os índices individualmente.
  def up
    create_table :custom_report_runs do |t|
      t.references :custom_report, null: false, foreign_key: true

      t.string :format, limit: 10, null: false, default: 'csv'
      t.string :status, limit: 20, null: false, default: 'pending'

      # Progresso. total_rows fica nulo até a contagem inicial terminar.
      t.integer :total_rows, null: true
      t.integer :processed_rows, null: false, default: 0

      # Arquivo gerado. Deliberadamente NÃO usa Store: Store::File.add recebe o
      # conteúdo inteiro como String (e o provider default pode ser 'DB'), o
      # que inviabiliza export de tamanho arbitrário. O arquivo é escrito em
      # streaming sob storage/custom_report_runs/<id>/, que em Docker é o
      # volume compartilhado zammad-storage — necessário porque o job roda no
      # container do scheduler e o download é servido pelo railsserver.
      t.string :filename, limit: 250, null: true
      t.bigint :filesize, null: true

      t.text :error, null: true

      # Arquivos de relatório podem ser grandes; sem expiração o disco enche.
      t.datetime :expires_at, limit: 3, null: true

      t.integer :updated_by_id, null: false
      t.integer :created_by_id, null: false
      t.timestamps limit: 3, null: false
    end

    # Lista "minhas gerações" e a limpeza por expiração.
    add_index :custom_report_runs, %i[created_by_id created_at]
    add_index :custom_report_runs, :status
    add_index :custom_report_runs, :expires_at
    add_foreign_key :custom_report_runs, :users, column: :created_by_id
    add_foreign_key :custom_report_runs, :users, column: :updated_by_id
  end

  def down
    drop_table :custom_report_runs, if_exists: true
  end
end
