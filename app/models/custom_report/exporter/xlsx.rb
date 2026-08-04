# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: export xlsx em streaming de relatório personalizado.

# Escreve a planilha linha por linha em disco.
#
# Não usa ExcelSheet de propósito: ele recebe os registros como Array e monta a
# planilha inteira em memória, o que inviabiliza relatórios grandes. Aqui o
# WriteXLSX roda em constant_memory, modo em que cada linha é descarregada em
# disco assim que a próxima começa — o custo de memória deixa de acompanhar o
# tamanho do resultado, como já acontece no export CSV.
class CustomReport::Exporter::Xlsx
  # Limite do próprio formato: uma planilha xlsx não passa de 1.048.576 linhas,
  # contando o cabeçalho. Acima disso o arquivo abriria truncado sem avisar, então
  # a geração falha com mensagem clara. Para volumes maiores existe o CSV.
  MAX_ROWS = 1_048_575

  attr_reader :run, :query, :columns, :summary, :on_progress

  # on_progress recebe o total processado depois de cada lote. Fica de fora desta
  # classe para que ela só cuide de escrever o arquivo.
  def initialize(run:, query:, columns:, summary: nil, on_progress: nil)
    @run         = run
    @query       = query
    @columns     = columns
    @summary     = summary
    @on_progress = on_progress
  end

  def call
    require 'write_xlsx' # Carrega a gem só quando é realmente usada.

    path = run.prepare_file_path!

    workbook = WriteXLSX.new(path.to_s, constant_memory: 1)
    processed = write_rows(workbook)
    write_summary(workbook)
    workbook.close

    { rows: processed, filesize: ::File.size(path), path: path }
  end

  private

  def write_rows(workbook)
    sheet    = workbook.add_worksheet(sheet_name(run.custom_report.name))
    header   = header_format(workbook)
    preloads = columns.preload_associations
    row      = 0

    columns.headers.each_with_index do |value, index|
      sheet.write_string(row, index, value, header)
    end

    processed = 0

    query.each_batch do |batch|
      batch = batch.includes(*preloads) if preloads.present?

      batch.each do |record|
        row += 1
        raise too_many_rows_error if row > MAX_ROWS

        write_row(sheet, row, columns.row(record))
        processed += 1
      end

      on_progress&.call(processed)
    end

    processed
  end

  # Totalizadores vão numa aba própria: misturá-los ao final da listagem
  # atrapalharia filtro e tabela dinâmica na planilha.
  def write_summary(workbook)
    result = summary&.call
    return if result.blank?

    sheet  = workbook.add_worksheet(sheet_name(translate(__('Totals'))))
    header = header_format(workbook)

    write_summary_header(sheet, result, header)
    write_summary_rows(sheet, result)
    write_totals_row(sheet, result, header)
  end

  def write_summary_header(sheet, result, format)
    titles = result[:group_by].pluck(:display) + result[:aggregations].pluck(:display)

    titles.each_with_index { |value, index| sheet.write_string(0, index, value, format) }
  end

  def write_summary_rows(sheet, result)
    result[:rows].each_with_index do |entry, index|
      values = result[:group_by].map { |group| entry[:groups][group[:name]] } +
               result[:aggregations].map { |aggregation| entry[:values][aggregation[:name]] }

      write_row(sheet, index + 1, values)
    end
  end

  def write_totals_row(sheet, result, format)
    return if result[:totals].blank?

    row = result[:rows].size + 1

    sheet.write_string(row, 0, translate(__('Total')), format)

    result[:aggregations].each_with_index do |aggregation, index|
      column = result[:group_by].size + index
      value  = result[:totals][aggregation[:name]]

      write_cell(sheet, row, column, value)
    end
  end

  def write_row(sheet, row, values)
    values.each_with_index { |value, column| write_cell(sheet, row, column, value) }
  end

  # Números precisam ir como número, senão a planilha não soma nem ordena. O
  # resto vai como texto: as colunas já chegam formatadas (datas em ISO, relações
  # pelo nome), e write_xlsx interpretaria uma string tipo "1-2" como data.
  def write_cell(sheet, row, column, value)
    case value
    when nil            then nil
    when Numeric        then sheet.write_number(row, column, value)
    else sheet.write_string(row, column, value.to_s)
    end
  end

  def translate(string)
    Translation.translate(columns.locale, string)
  end

  def header_format(workbook)
    format = workbook.add_format
    format.set_bold
    format
  end

  # Excel rejeita nome de aba com mais de 31 caracteres ou com : \ / ? * [ ]
  def sheet_name(name)
    name.to_s.gsub(%r{[:\\/?*\[\]]}, ' ').strip.truncate(31).presence || 'Report'
  end

  def too_many_rows_error
    message = format(
      __('The report has more rows than a spreadsheet can hold (%s). Please narrow the filters or export as CSV.'),
      MAX_ROWS
    )

    CustomReport::Exporter::TooManyRowsError.new(translate(message))
  end
end
