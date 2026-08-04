# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: agrupamento e totalizadores de um relatório personalizado.

# Calcula os totalizadores do relatório: um valor agregado por combinação dos
# atributos de agrupamento, mais a linha de total geral.
#
# Ponto de atenção: função e atributo vêm do modelo salvo e entram no SELECT.
# Ambos são validados contra listas fechadas antes disso — função contra
# FUNCTIONS, atributo contra as colunas reais do objeto — de modo que nada vindo
# do banco chega cru ao SQL.
class CustomReport::Summary
  # 'count' não recebe atributo: conta os registros do grupo.
  FUNCTIONS = %w[count sum avg min max].freeze

  FUNCTION_LABELS = {
    'count' => __('Count'),
    'sum'   => __('Sum'),
    'avg'   => __('Average'),
    'min'   => __('Minimum'),
    'max'   => __('Maximum'),
  }.freeze

  # sum e avg só fazem sentido em coluna numérica; nas outras devolveriam erro do
  # banco ou um número sem significado.
  NUMERIC_ONLY  = %w[sum avg].freeze
  NUMERIC_TYPES = %i[integer float decimal].freeze

  # Teto de linhas do resumo. Agrupar por um atributo de alta cardinalidade
  # (título, por exemplo) geraria praticamente uma linha por registro.
  MAX_GROUPS = 1_000

  attr_reader :report, :query, :columns

  def initialize(report:, query:, columns:)
    @report  = report
    @query   = query
    @columns = columns
  end

  # nil quando o relatório não define agregação nenhuma — assim o chamador
  # simplesmente não renderiza a seção.
  def call
    return if aggregations.blank?

    {
      group_by:     group_metadata,
      aggregations: aggregation_metadata,
      rows:         rows,
      totals:       totals,
    }
  end

  private

  def target_class
    report.target_class
  end

  def table
    target_class.table_name
  end

  # Atributos de agrupamento, normalizados (state -> state_id) e restritos a
  # colunas reais.
  def group_attributes
    @group_attributes ||= report.normalize_attributes(report.group_by)
  end

  # O modelo guarda as funções escolhidas em `aggregations` e os atributos em
  # `aggregation_attributes`; aqui sai o produto dos dois. 'count' não usa
  # atributo e entra uma única vez.
  #
  # Combinação inválida é descartada em silêncio, não levantada: um modelo salvo
  # com uma escolha que deixou de fazer sentido (o campo virou texto, por exemplo)
  # ainda deve conseguir gerar o resto do relatório.
  def aggregations
    @aggregations ||= functions.flat_map do |function|
      next [{ function: 'count', attribute: nil, name: 'count' }] if function == 'count'

      aggregation_columns.filter_map { |column| build_aggregation(function, column) }
    end
  end

  def functions
    Array.wrap(report.aggregations).map(&:to_s).uniq.select { |function| FUNCTIONS.include?(function) }
  end

  def aggregation_columns
    @aggregation_columns ||= report.normalize_attributes(report.aggregation_attributes)
  end

  def build_aggregation(function, column)
    return if NUMERIC_ONLY.include?(function) && !numeric_column?(column)

    { function: function, attribute: column, name: "#{function}_#{column}" }
  end

  def numeric_column?(column)
    NUMERIC_TYPES.include?(target_class.columns_hash[column]&.type)
  end

  # Agrega sobre os ids que a consulta permitida devolve, e não sobre a própria
  # relação.
  #
  # A relação carrega `distinct` e possivelmente joins vindos das condições; um
  # SUM direto sobre ela contaria o mesmo registro mais de uma vez para cada linha
  # duplicada pelo join. Passar pelos ids garante um registro por linha sem abrir
  # mão do recorte de permissão.
  def base
    @base ||= target_class.where(id: query.relation.select(:id))
  end

  def rows
    @rows ||= begin
      if group_attributes.blank?
        []
      else
        build_rows(grouped_values)
      end
    end
  end

  def grouped_values
    base
      .group(*group_columns)
      .limit(MAX_GROUPS)
      .pluck(*(group_columns + aggregation_selects))
      .map { |values| Array.wrap(values) }
  end

  # Resolve os nomes das relações em um passe, e só para os ids que aparecem no
  # resultado. Carregar a tabela relacionada inteira traria a base de usuários
  # completa para agrupar por proprietário.
  def build_rows(grouped)
    lookups = build_lookups(grouped)

    grouped.map do |values|
      groups = group_attributes.each_with_index.to_h do |attribute, index|
        value = values[index]
        [attribute, value.nil? ? nil : lookups.dig(attribute, value) || value]
      end

      aggregated = aggregations.each_with_index.to_h do |aggregation, index|
        [aggregation[:name], cast(values[group_attributes.size + index])]
      end

      { groups: groups, values: aggregated }
    end
  end

  def build_lookups(grouped)
    group_attributes.each_with_object({}).with_index do |(attribute, result), index|
      next if !attribute.end_with?('_id')

      klass = relation_class(attribute)
      next if klass.nil?

      ids = grouped.filter_map { |values| values[index] }.uniq
      next if ids.blank?

      result[attribute] = klass.where(id: ids).index_by(&:id).transform_values { |record| display_of(record) }
    end
  end

  def relation_class(attribute)
    target_class.reflect_on_association(attribute.delete_suffix('_id'))&.klass
  rescue NameError
    nil
  end

  def display_of(record)
    return record.fullname if record.respond_to?(:fullname)
    return record.name if record.respond_to?(:name)

    record.id
  end

  def totals
    values = Array.wrap(base.pick(*aggregation_selects))

    aggregations.each_with_index.to_h do |aggregation, index|
      [aggregation[:name], cast(values[index])]
    end
  end

  def group_columns
    @group_columns ||= group_attributes.map { |attribute| Arel.sql("#{table}.#{attribute}") }
  end

  # Montado só depois da validação de função e coluna.
  def aggregation_selects
    @aggregation_selects ||= aggregations.map do |aggregation|
      if aggregation[:function] == 'count'
        Arel.sql("COUNT(DISTINCT #{table}.id)")
      else
        Arel.sql("#{aggregation[:function].upcase}(#{table}.#{aggregation[:attribute]})")
      end
    end
  end

  # AVG volta como BigDecimal; arredonda para a planilha e o grid mostrarem algo
  # legível em vez de 30 casas.
  def cast(value)
    case value
    when BigDecimal then value.round(2).to_f
    when Float      then value.round(2)
    else value
    end
  end

  def group_metadata
    group_attributes.map { |attribute| { name: attribute, display: columns.display_for(attribute) } }
  end

  def aggregation_metadata
    aggregations.map do |aggregation|
      {
        name:      aggregation[:name],
        display:   aggregation_display(aggregation),
        function:  aggregation[:function],
        attribute: aggregation[:attribute],
      }
    end
  end

  def aggregation_display(aggregation)
    label = Translation.translate(columns.locale, FUNCTION_LABELS.fetch(aggregation[:function]))
    return label if aggregation[:attribute].blank?

    "#{label} (#{columns.display_for(aggregation[:attribute])})"
  end
end
