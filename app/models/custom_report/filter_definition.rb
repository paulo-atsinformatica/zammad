# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: descreve um filtro oferecido na tela de visualização.

# Diz à tela QUE controle usar para cada filtro habilitado, e com quais opções.
#
# Sem isto a tela só sabe o nome do atributo e cai num input de texto para tudo,
# o que é inútil para estado, grupo ou data.
class CustomReport::FilterDefinition
  # 'select' vem com `options`; 'agent', 'customer' e 'organization' são campos
  # de busca com autocomplete (o mesmo controle usado no resto do Zammad); os
  # demais são controles simples.
  TYPES = %w[select agent customer organization date boolean number text].freeze

  # Colunas *_id cuja relação é grande demais para virar lista (ver
  # ENUMERABLE_RELATIONS) ganham o campo de busca correspondente. Sem isto elas
  # caíam em 'text', o operador 'contains' virava ILIKE e o Postgres recusava a
  # consulta: `operator does not exist: integer ~~* unknown`.
  #
  # A chave é a classe da relação; owner_id é exceção por buscar só entre
  # atendentes, que é o conjunto útil para "Proprietário".
  AUTOCOMPLETE_BY_RELATION = {
    'User'         => 'customer',
    'Organization' => 'organization',
  }.freeze

  AGENT_ATTRIBUTES = %w[owner_id].freeze

  # Operadores que cada tipo aceita. O operador chega da requisição e vai direto
  # ao Selector::Sql, então precisa ser restrito: um valor desconhecido levanta
  # exceção lá dentro, e um inesperado ('is set' num texto, por exemplo) mudaria
  # o significado do filtro. A interseção com VALID_OPERATORS mantém isto em
  # sincronia com o upstream.
  # Os tipos que resolvem para uma coluna *_id (select e os de autocomplete) só
  # aceitam igualdade: o valor comparado é um id, e um 'contains' ali vira ILIKE
  # sobre integer, que o Postgres recusa.
  OPERATORS_BY_TYPE = {
    'select'       => ['is', 'is not'],
    'agent'        => ['is', 'is not'],
    'customer'     => ['is', 'is not'],
    'organization' => ['is', 'is not'],
    'number'       => ['is', 'is not'],
    'date'         => ['after (absolute)', 'before (absolute)'],
    'boolean'      => ['is'],
    'text'         => ['contains', 'contains not', 'is', 'is not', 'starts with one of', 'ends with one of'],
  }.freeze

  # Relações cuja lista inteira pode ser oferecida como opção.
  #
  # Deliberadamente NÃO inclui User nem Organization: são tabelas grandes, e
  # despejar todos os nomes na tela seria tanto um problema de volume quanto de
  # privacidade — quem só atende um grupo passaria a ver a base de clientes
  # inteira. Esses continuam como texto, filtrando por "contém".
  ENUMERABLE_RELATIONS = %w[
    Ticket::State
    Ticket::Priority
    Ticket::Article::Type
    Ticket::Article::Sender
  ].freeze

  attr_reader :name, :display, :target_class, :user

  def initialize(name:, display:, target_class:, user:)
    @name         = name.to_s
    # O rótulo é non-null no GraphQL; sem esta rede um atributo sem rótulo
    # derrubaria a consulta inteira da tela, e não só o próprio filtro.
    @display      = display.presence || @name.delete_suffix('_id').humanize
    @target_class = target_class
    @user         = user
  end

  def to_h
    result = { name: name, display: display, type: type }
    result[:options] = options if type == 'select'
    result
  end

  def type
    @type ||= resolve_type
  end

  def options
    relation_options || []
  end

  def permitted_operators
    @permitted_operators ||= (OPERATORS_BY_TYPE[type] || []) & Selector::Sql::VALID_OPERATORS
  end

  def permits?(operator)
    permitted_operators.include?(operator.to_s)
  end

  private

  # Método separado, e não `begin...end` com `return`: dentro de uma atribuição o
  # `return` sai do método sem atribuir, e a memoização nunca acontecia.
  def resolve_type
    return 'select' if relation_options.present?
    return autocomplete_type if autocomplete_type
    return 'date' if date_column?
    return 'boolean' if column&.type == :boolean

    # Rede de segurança: nenhuma coluna numérica pode cair em 'text', senão o
    # operador 'contains' gera ILIKE sobre integer e derruba a consulta.
    return 'number' if numeric_column?

    'text'
  end

  # Campo de busca para as relações que não cabem numa lista. Devolve nil quando
  # o atributo não é uma dessas, para o resolve_type seguir adiante.
  def autocomplete_type
    return @autocomplete_type if defined?(@autocomplete_type)

    @autocomplete_type = begin
      klass = relation_class

      if klass.nil?
        nil
      elsif AGENT_ATTRIBUTES.include?(name) && klass <= User
        'agent'
      else
        AUTOCOMPLETE_BY_RELATION[klass.name]
      end
    end
  end

  def numeric_column?
    %i[integer bigint decimal float].include?(column&.type)
  end

  def column
    @column ||= target_class.columns_hash[name]
  end

  def date_column?
    %i[date datetime].include?(column&.type)
  end

  # Grupo é caso especial: a lista é pequena, mas precisa ser recortada pelos
  # grupos que este usuário pode ler. Oferecer um grupo que ele não enxerga
  # geraria um filtro que nunca retorna nada, além de revelar a existência do
  # grupo.
  def relation_options
    return @relation_options if defined?(@relation_options)

    @relation_options = begin
      klass = relation_class

      if klass.nil?
        nil
      elsif klass == Group
        build_options(visible_groups)
      elsif ENUMERABLE_RELATIONS.include?(klass.name)
        build_options(klass.reorder(name: :asc))
      end
    end
  end

  def relation_class
    return if !name.end_with?('_id')

    association = target_class.reflect_on_association(name.delete_suffix('_id'))
    association&.klass
  rescue NameError => e
    # Associação polimórfica ou modelo inexistente: cai para texto.
    Rails.logger.debug { "Could not resolve relation for #{target_class}##{name}: #{e.message}" }
    nil
  end

  def visible_groups
    return Group.reorder(name: :asc) if user&.permissions?('admin')

    Group.where(id: user&.group_ids_access('read')).reorder(name: :asc)
  end

  # O valor é o id, porque a coluna filtrada é *_id. O rótulo é traduzido para
  # os modelos de referência (estado "open" aparece como "aberto").
  def build_options(records)
    locale = user.try(:locale) || Setting.get('locale_default') || 'en-us'

    records.map do |record|
      { value: record.id, label: Translation.translate(locale, record.name.to_s) }
    end
  end
end
