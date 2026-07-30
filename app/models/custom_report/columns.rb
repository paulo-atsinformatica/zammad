# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: resolve colunas e valores de um relatório personalizado.

# Traduz a lista de colunas escolhida no relatório em cabeçalhos legíveis e
# extrai os valores de cada registro.
class CustomReport::Columns
  attr_reader :report, :user, :locale

  def initialize(report:, user:)
    @report = report
    @user   = user
    @locale = user.try(:locale) || Setting.get('locale_default') || 'en-us'
  end

  def names
    @names ||= begin
      # Normaliza (state -> state_id) e descarta o que não corresponde a coluna
      # nenhuma. Sem isso, um valor inesperado em report.columns viraria uma
      # coluna literal na planilha.
      selected = Array.wrap(report.columns)
        .select { |name| name.is_a?(String) || name.is_a?(Symbol) }
        .then { |names| report.normalize_attributes(names) }

      selected.presence || default_names
    end
  end

  # Cabeçalho na língua do usuário, usando o rótulo do campo e não o nome da
  # coluna do banco. Passa por display_for para valer a mesma garantia de nunca
  # devolver vazio.
  def headers
    names.map { |name| display_for(name) }
  end

  # Associações a pré-carregar. Sem isto, resolver cada coluna *_id faria uma
  # query por linha — inviável num relatório de centenas de milhares de linhas.
  def preload_associations
    names.filter_map do |name|
      next if !name.end_with?('_id')

      association = name.delete_suffix('_id').to_sym
      association if report.target_class.reflect_on_association(association)
    end
  end

  def row(record)
    names.map { |name| value(record, name) }
  end

  # Rótulo traduzido de um atributo qualquer, não só das colunas exibidas.
  # Usado para os filtros oferecidos na tela.
  #
  # Nunca devolve vazio: o rótulo é campo non-null no GraphQL, e um atributo sem
  # rótulo derrubaria a consulta inteira da tela em vez de aparecer sem nome.
  def display_for(name)
    name = name.to_s
    translated = Translation.translate(locale, display_name(name)).to_s

    translated.presence || name.delete_suffix('_id').humanize.presence || name
  end

  private

  def attributes
    @attributes ||= ObjectManager::Object
      .new(report.object)
      .attributes(user, skip_permission: user.nil?)
      .index_by { |item| item[:name].to_s }
  rescue => e
    Rails.logger.debug { "Could not load object attributes for #{report.object}: #{e.message}" }
    {}
  end

  def default_names
    report.target_class.column_names & %w[number title name state_id priority_id group_id owner_id customer_id organization_id created_at updated_at]
  end

  # ObjectManager filtra atributos por permissão, então nem toda coluna tem
  # rótulo disponível. Nesse caso um nome humanizado ("Group") é melhor de ler
  # numa planilha que o nome da coluna ("group_id").
  def display_name(name)
    attributes.dig(name, :display).presence || name.delete_suffix('_id').humanize
  end

  def value(record, name)
    raw = extract(record, name)

    case raw
    when nil            then nil
    when Time, DateTime then raw.in_time_zone(time_zone).iso8601
    when Date           then raw.iso8601
    when Array          then raw.join(', ')
    else
      translatable?(name) ? Translation.translate(locale, raw.to_s) : raw
    end
  end

  # Colunas *_id são exportadas pelo nome do registro relacionado, não pelo id,
  # porque o destino é um humano lendo a planilha.
  def extract(record, name)
    if name.end_with?('_id')
      association = name.delete_suffix('_id')
      return display_of(record.public_send(association)) if record.respond_to?(association)
    end

    record.public_send(name) if record.respond_to?(name)
  end

  # Não dá para usar to_s: a maioria dos modelos de relação do Zammad
  # (Ticket::State, Group, Ticket::Priority) não sobrescreve to_s, e o valor
  # sairia como #<Ticket::State:0x...> na planilha.
  def display_of(related)
    return if related.nil?
    return related.fullname if related.respond_to?(:fullname)
    return related.name if related.respond_to?(:name)

    related.to_s
  end

  def translatable?(name)
    attributes.dig(name, :translate).present?
  end

  def time_zone
    Setting.get('timezone_default').presence || 'UTC'
  end
end
