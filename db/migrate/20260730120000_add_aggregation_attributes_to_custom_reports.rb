# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: totalizadores do relatório personalizado.

class AddAggregationAttributesToCustomReports < ActiveRecord::Migration[8.0]
  # `aggregations` guarda as funções escolhidas (count, sum, avg, min, max) e esta
  # coluna guarda os atributos sobre os quais elas se aplicam. Dois campos em vez
  # de pares função+atributo porque assim o formulário usa componentes que já
  # existem, sem precisar de um elemento de UI próprio para editar pares.
  def up
    return if column_exists?(:custom_reports, :aggregation_attributes)

    add_column :custom_reports, :aggregation_attributes, :jsonb, null: false, default: []
  end

  def down
    remove_column :custom_reports, :aggregation_attributes, if_exists: true
  end
end
