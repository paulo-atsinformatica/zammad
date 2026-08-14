# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: monta a consulta de um relatório personalizado.

# Ponto central de segurança do relatório personalizado.
#
# O modelo salvo guarda apenas condições; ele nunca concede acesso. Toda
# execução parte do scope de permissão de QUEM está gerando e só então aplica
# as condições, de modo que um relatório compartilhado (ou global) não pode
# revelar registro algum que o usuário não veria por conta própria.
#
# Vale notar que Selector::Sql NÃO filtra por permissão — ele usa current_user
# apenas para resolver pré-condições como "meus tickets". A interseção com o
# scope aqui é obrigatória.
class CustomReport::Query
  # Escopo de permissão por objeto base.
  POLICY_SCOPES = {
    'Ticket'       => 'TicketPolicy::ReadScope',
    'User'         => 'UserPolicy::Scope',
    'Organization' => 'OrganizationPolicy::Scope',
  }.freeze

  # Válvula de segurança: mesmo enfileirado, uma consulta sem filtro varreria a
  # base inteira. Configurável via setting.
  DEFAULT_MAX_ROWS = 500_000

  DEFAULT_PER_PAGE = 50
  MAX_PER_PAGE     = 200

  attr_reader :report, :user, :filters

  # filters: condições informadas por quem está visualizando, no mesmo formato
  # de selector. São restritas aos atributos que o modelo habilitou.
  def initialize(report:, user:, filters: nil)
    @report  = report
    @user    = user
    @filters = filters
  end

  def relation
    @relation ||= begin
      scope = permitted_scope

      query, bind_params, tables = target_class.selector2sql(
        effective_condition,
        current_user: user,
      )

      scope = scope.where(query, *bind_params).joins(tables) if query.present?
      scope.distinct
    end
  end

  # Condição salva no modelo somada aos filtros preenchidos na hora.
  #
  # Filtros de runtime só entram se o modelo os habilitou: sem isso, quem
  # visualiza poderia filtrar por atributos que o autor não quis expor.
  def effective_condition
    saved = (report.condition || {}).to_h
    return saved if runtime_filters.blank?

    saved.merge(runtime_filters)
  end

  def runtime_filters
    return @runtime_filters if defined?(@runtime_filters)

    @runtime_filters = allowed_runtime_filters
  end

  # Página de resultados para exibição em grid.
  #
  # group_by entra antes da ordenação escolhida: sem isso os registros de uma
  # mesma seção ficariam espalhados pela página e o grid agrupado mostraria a
  # mesma seção várias vezes.
  def page(page: 1, per_page: DEFAULT_PER_PAGE, order_by: nil, order_direction: 'asc', group_by: nil)
    per_page = per_page.to_i.clamp(1, MAX_PER_PAGE)
    page     = [page.to_i, 1].max

    ordered(order_by, order_direction, group_by)
      .offset((page - 1) * per_page)
      .limit(per_page)
  end

  def count
    relation.count
  end

  def max_rows
    (Setting.get('custom_report_max_rows').presence || DEFAULT_MAX_ROWS).to_i
  end

  def exceeds_max_rows?
    count > max_rows
  end

  # Percorre os registros em lotes, para que o consumo de memória não cresça
  # com o tamanho do relatório.
  def each_batch(batch_size: 500, &)
    relation.reorder(id: :asc).in_batches(of: batch_size, &)
  end

  def target_class
    report.target_class
  end

  private

  # enabled_filters guarda o nome da coluna ("title"), que é o que dá para
  # validar contra o objeto. O Selector::Sql, porém, espera a chave prefixada
  # pelo objeto ("ticket.title"), então a conversão acontece aqui.
  #
  # Aceita as duas formas na entrada: a tela pode mandar o nome simples ou já
  # a chave de selector.
  def allowed_runtime_filters
    given = (filters || {}).to_h
    return {} if given.blank?

    # Normaliza os dois lados (state -> state_id), já que a interface salva o
    # nome sem o sufixo de relação.
    allowed = report.normalize_attributes(report.enabled_filters)
    return {} if allowed.blank?

    given.each_with_object({}) do |(key, value), result|
      attribute = CustomReport.normalize_attribute(key.to_s.split('.').last, target_class)
      next if attribute.blank?
      next if allowed.exclude?(attribute)

      condition = permitted_condition(attribute, value)
      next if condition.blank?

      result["#{selector_prefix}.#{attribute}"] = condition
    end
  end

  # O operador chega da requisição e iria direto ao Selector::Sql. Só passa o que
  # o tipo do atributo permite (ver CustomReport::FilterDefinition).
  def permitted_condition(attribute, value)
    condition = value.respond_to?(:to_h) ? value.to_h.symbolize_keys : {}
    operator  = condition[:operator].to_s
    return if !filter_definition(attribute).permits?(operator)

    # Campo em branco significa "não filtrar por isto". Comparado com nil e ''
    # em vez de blank? para não descartar um filtro booleano em `false`.
    return if condition[:value].nil? || condition[:value] == ''

    value = normalize_filter_value(condition[:value])
    return if value.nil?

    { operator: operator, value: value }
  end

  # O intervalo de datas ('in range') chega como [de, até], e um lado vazio é
  # legítimo — significa "sem limite deste lado", que o Selector::Sql resolve
  # como >= ou <=. Já os dois lados vazios fariam ele levantar exceção
  # ("Invalid value in range"), então isso vira "não filtrar por isto".
  #
  # Devolve nil quando o filtro deve ser descartado.
  def normalize_filter_value(value)
    return value if !value.is_a?(Array)

    normalized = value.map { |item| item.to_s.strip.presence }
    return if normalized.compact.empty?

    normalized
  end

  def filter_definition(attribute)
    @filter_definitions ||= {}
    @filter_definitions[attribute] ||= CustomReport::FilterDefinition.new(
      name:         attribute,
      display:      attribute,
      target_class: target_class,
      user:         user,
    )
  end

  def selector_prefix
    report.object.underscore
  end

  # Só ordena por coluna real da tabela: o valor vem da requisição e iria direto
  # para o ORDER BY. Vale para o agrupamento também, que vem do modelo salvo.
  def ordered(order_by, order_direction, group_by = nil)
    column    = target_class.column_names.include?(order_by.to_s) ? order_by.to_s : 'id'
    direction = order_direction.to_s.casecmp('desc').zero? ? :desc : :asc

    group = group_by.to_s if target_class.column_names.include?(group_by.to_s)
    return relation.reorder(group => :asc, column => direction) if group.present? && group != column

    relation.reorder(column => direction)
  end

  def permitted_scope
    scope_name = POLICY_SCOPES[report.object]
    raise "Unsupported custom report object '#{report.object}'" if scope_name.blank?

    scope_name.constantize.new(user, target_class).resolve
  end
end
