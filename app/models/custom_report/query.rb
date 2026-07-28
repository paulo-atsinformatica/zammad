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

  attr_reader :report, :user

  def initialize(report:, user:)
    @report = report
    @user   = user
  end

  def relation
    @relation ||= begin
      scope = permitted_scope

      query, bind_params, tables = target_class.selector2sql(
        report.condition,
        current_user: user,
      )

      scope = scope.where(query, *bind_params).joins(tables) if query.present?
      scope.distinct
    end
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
  def each_batch(batch_size: 500, &block)
    relation.reorder(id: :asc).in_batches(of: batch_size, &block)
  end

  def target_class
    report.target_class
  end

  private

  def permitted_scope
    scope_name = POLICY_SCOPES[report.object]
    raise "Unsupported custom report object '#{report.object}'" if scope_name.blank?

    scope_name.constantize.new(user, target_class).resolve
  end
end
