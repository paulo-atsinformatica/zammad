# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: agrupamento do grid de um relatório personalizado.

# Quebra o grid em seções por um atributo, como faz a Visão Geral, e diz quantos
# registros cada seção tem.
#
# A contagem é do resultado inteiro, e não da página carregada: a pergunta que o
# agrupamento responde é "quantos cada um tem", e um número que mudasse a cada
# página não responderia nada.
#
# Usa o primeiro atributo de `group_by` do modelo. O grid é uma lista, então
# quebrar por mais de um nível exigiria seções aninhadas; os demais atributos
# seguem valendo para a tabela de totalizadores (ver CustomReport::Summary).
class CustomReport::Grouping
  # Teto de seções. Agrupar por um atributo de alta cardinalidade (título, por
  # exemplo) renderizaria praticamente uma seção por registro.
  MAX_GROUPS = 500

  attr_reader :report, :user, :query, :columns

  def initialize(report:, user:, query:, columns:)
    @report  = report
    @user    = user
    @query   = query
    @columns = columns
  end

  # Nome deliberadamente diferente de present?/blank?: sem receptor, blank?
  # chamaria Object#blank? do ActiveSupport nesta própria instância de Grouping
  # (sempre false, por não responder a empty?), não o meu predicado sobre
  # attribute. Foi exatamente essa confusão que um rubocop -A anterior
  # introduziu, reescrevendo `!present?` como `blank?` e quebrando o guard.
  def grouped?
    attribute.present?
  end

  def attribute
    return @attribute if defined?(@attribute)

    @attribute = report.normalize_attributes(report.group_by).first
  end

  def to_h
    return if !grouped?

    { name: attribute, display: columns.display_for(attribute) }
  end

  # Rótulo da seção a que este registro pertence. Sai formatado como as células
  # do grid, para a seção "Paulo Mota" bater com a coluna Proprietário.
  def value_for(record)
    return if !grouped?

    columns.display_value(record, attribute)
  end

  # [{ value: <rótulo>, count: n }], na mesma ordem em que as seções aparecem.
  def counts
    return [] if !grouped?

    @counts ||= begin
      raw = base.group(attribute).reorder(attribute).limit(MAX_GROUPS).count
      lookups = build_lookups(raw.keys)

      raw.map do |key, count|
        { value: label_for(key, lookups), count: count }
      end
    end
  end

  private

  def target_class
    report.target_class
  end

  # Agrega sobre os ids que a consulta permitida devolve, e não sobre a própria
  # relação: ela carrega `distinct` e possivelmente joins vindos das condições, e
  # um COUNT direto contaria o mesmo registro uma vez por linha duplicada.
  # Mesmo cuidado de CustomReport::Summary#base.
  def base
    @base ||= target_class.where(id: query.relation.select(:id))
  end

  # Resolve os nomes das relações num passe só, e apenas para os ids presentes.
  # Carregar a tabela relacionada inteira traria a base de usuários completa para
  # agrupar por proprietário.
  def build_lookups(keys)
    return {} if !attribute.end_with?('_id')

    klass = relation_class
    return {} if klass.nil?

    ids = keys.compact
    return {} if ids.blank?

    klass.where(id: ids).index_by(&:id).transform_values { |record| display_of(record) }
  end

  def relation_class
    target_class.reflect_on_association(attribute.delete_suffix('_id'))&.klass
  rescue NameError
    nil
  end

  def display_of(record)
    return record.fullname if record.respond_to?(:fullname)
    return record.name if record.respond_to?(:name)

    record.id.to_s
  end

  # Registro sem valor no atributo ainda forma uma seção — some-lo esconderia
  # linhas que o grid vai exibir de qualquer forma.
  def label_for(key, lookups)
    return '-' if key.nil? || key.to_s.empty?

    (lookups[key] || key).to_s
  end
end
