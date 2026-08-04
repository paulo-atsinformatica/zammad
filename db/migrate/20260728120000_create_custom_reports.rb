# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: relatório personalizado.

class CreateCustomReports < ActiveRecord::Migration[8.0]
  # up/down explícitos em vez de `change`: na reversão automática o Rails tenta
  # remover os índices um a um antes do drop_table e falha, mesmo eles existindo.
  # O drop_table já leva índices e chaves estrangeiras junto.
  def up
    create_table :custom_reports do |t|
      t.string :name, limit: 250, null: false

      # Objeto que representa a linha do relatório. Fase 1 gera apenas Ticket,
      # mas a coluna já existe para User/Organization não exigirem migration.
      # Nome 'object' segue a convenção de CoreWorkflow e é o que
      # ChecksConditionValidation espera para resolver a classe alvo.
      t.string :object, limit: 100, null: false, default: 'Ticket'

      # Quem enxerga o MODELO salvo. Não tem relação com o escopo dos dados:
      # a consulta é sempre interceptada pelas permissões de quem gera
      # (ver CustomReport::Query), então um relatório global não expõe nada
      # além do que o próprio usuário já poderia ver.
      t.string :visibility, limit: 20, null: false, default: 'personal'

      # Condição no formato de selector do Zammad. text + `store` para
      # acompanhar Overview e Job: é assim que o Selector::Sql recebe condições
      # no resto do Zammad, e o coder do store entrega
      # HashWithIndifferentAccess, que é o que ele espera.
      t.text :condition, null: true

      # Estes três são listas, e a macro `store` do Zammad só serve para Hash —
      # com ela um Array é silenciosamente convertido em {}. Por isso jsonb, que
      # guarda array nativamente.
      t.jsonb :columns, null: false, default: []
      t.jsonb :group_by, null: false, default: []
      t.jsonb :aggregations, null: false, default: []

      t.boolean :active, null: false, default: true
      t.integer :updated_by_id, null: false
      t.integer :created_by_id, null: false
      t.timestamps limit: 3, null: false
    end

    add_index :custom_reports, %i[visibility active]
    add_index :custom_reports, :created_by_id
    add_index :custom_reports, :name
    add_foreign_key :custom_reports, :users, column: :created_by_id
    add_foreign_key :custom_reports, :users, column: :updated_by_id

    # Grupos que enxergam o modelo quando visibility = 'group'.
    create_table :custom_reports_groups, id: false do |t|
      t.references :custom_report, null: false, foreign_key: true
      t.references :group, null: false, foreign_key: true
    end

    add_index :custom_reports_groups, %i[custom_report_id group_id], unique: true, name: 'index_custom_reports_groups'
  end

  def down
    drop_table :custom_reports_groups, if_exists: true
    drop_table :custom_reports, if_exists: true
  end
end
