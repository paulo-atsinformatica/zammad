# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: página de resultados de um relatório personalizado.

# Monta uma página de resultados pronta para um grid: metadados das colunas,
# linhas já formatadas e informação de paginação.
#
# Deliberadamente independente de transporte (nada de params ou render aqui),
# para servir tanto o endpoint REST quanto a query GraphQL da tela nova.
class CustomReport::Result
  attr_reader :report, :user, :filters, :page, :per_page, :order_by, :order_direction

  def initialize(report:, user:, filters: nil, page: 1, per_page: nil, order_by: nil, order_direction: 'asc')
    @report          = report
    @user            = user
    @filters         = filters
    @page            = [page.to_i, 1].max
    @per_page        = (per_page.presence || CustomReport::Query::DEFAULT_PER_PAGE).to_i
    @order_by        = order_by
    @order_direction = order_direction
  end

  def call
    {
      columns:         column_metadata,
      enabled_filters: filter_metadata,
      rows:            rows,
      total_count:     total_count,
      page:            page,
      per_page:        effective_per_page,
      total_pages:     total_pages,
    }
  end

  private

  def query
    @query ||= CustomReport::Query.new(report: report, user: user, filters: filters)
  end

  def columns
    @columns ||= CustomReport::Columns.new(report: report, user: user)
  end

  def effective_per_page
    @effective_per_page ||= per_page.clamp(1, CustomReport::Query::MAX_PER_PAGE)
  end

  def total_count
    @total_count ||= query.count
  end

  def total_pages
    return 0 if total_count.zero?

    (total_count.to_f / effective_per_page).ceil
  end

  # Nome e rótulo de cada coluna, para o grid montar o cabeçalho sem precisar
  # saber nada sobre os atributos do objeto.
  def column_metadata
    columns.names.each_with_index.map do |name, index|
      {
        name:    name,
        display: columns.headers[index],
      }
    end
  end

  # Quais filtros a tela deve oferecer, com rótulo já traduzido.
  def filter_metadata
    report.normalize_attributes(report.enabled_filters).map do |name|
      {
        name:    name,
        display: columns.display_for(name),
      }
    end
  end

  def rows
    records = query.page(
      page:            page,
      per_page:        effective_per_page,
      order_by:        order_by,
      order_direction: order_direction,
    )

    preloads = columns.preload_associations
    records  = records.includes(*preloads) if preloads.present?

    records.map do |record|
      {
        id:     record.id,
        values: columns.names.zip(columns.row(record)).to_h,
      }
    end
  end
end
