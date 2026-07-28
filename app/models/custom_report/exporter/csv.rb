# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: export CSV em streaming de relatório personalizado.

require 'csv'

# Escreve o relatório linha por linha em disco, para que o uso de memória não
# acompanhe o tamanho do resultado — é o que permite exportar sem limite de
# tamanho, ao contrário do ExcelSheet, que monta a planilha toda em memória.
class CustomReport::Exporter::Csv
  # Excel em pt-BR usa ; como separador e precisa de BOM para reconhecer UTF-8;
  # sem isso o usuário abre a planilha com acentuação corrompida e tudo numa
  # única coluna.
  COL_SEP = ';'
  BOM     = "\xEF\xBB\xBF"

  attr_reader :run, :query, :columns, :on_progress

  # on_progress recebe o total processado depois de cada lote. Fica de fora
  # desta classe para que ela só cuide de escrever o arquivo.
  def initialize(run:, query:, columns:, on_progress: nil)
    @run         = run
    @query       = query
    @columns     = columns
    @on_progress = on_progress
  end

  def call
    path      = run.prepare_file_path!
    preloads  = columns.preload_associations
    processed = 0

    ::File.open(path, 'wb') do |file|
      file.write(BOM)

      csv = ::CSV.new(file, col_sep: COL_SEP)
      csv << columns.headers

      query.each_batch do |batch|
        batch = batch.includes(*preloads) if preloads.present?

        batch.each do |record|
          csv << columns.row(record)
          processed += 1
        end

        file.flush
        on_progress&.call(processed)
      end
    end

    { rows: processed, filesize: ::File.size(path), path: path }
  end
end
