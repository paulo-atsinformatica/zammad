# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: modelo salvo de relatório personalizado.

class CustomReport < ApplicationModel
  include HasDefaultModelUserRelations
  include ChecksClientNotification
  include HasAuditLogs
  include ChecksConditionValidation
  # CanSearch alimenta o grid de Gerenciar > Relatórios Personalizados, que
  # pagina via /custom_reports/search. Depende de CanSelector por causa do
  # selector2sql usado em CanSearch#search_sql_base. Sem HasSearchIndexBackend
  # de propósito: a busca sempre roda no banco, sem depender do Elasticsearch.
  include CanSelector
  include CanSearch

  # Objetos que podem ser a linha do relatório. Fase 1 executa apenas Ticket;
  # os outros já validam para permitir salvar modelos antes da fase 2.
  OBJECTS = %w[Ticket User Organization].freeze

  # 'personal' = só quem criou; 'group' = membros dos grupos escolhidos;
  # 'global'   = qualquer usuário com a permissão report.custom.
  #
  # Isto controla apenas quem enxerga o MODELO. O escopo dos DADOS é sempre
  # recalculado a partir das permissões de quem gera (ver CustomReport::Query),
  # de forma que um relatório global nunca revela algo que o usuário não
  # poderia ver por conta própria.
  VISIBILITIES = %w[personal group global].freeze

  # Permissão necessária para salvar em cada nível. 'personal' não exige nada
  # além de report.custom, já que o modelo não sai do próprio usuário.
  VISIBILITY_PERMISSIONS = {
    'group'  => 'report.custom.group',
    'global' => 'report.custom.global',
  }.freeze

  has_and_belongs_to_many :groups
  has_many :custom_report_runs, dependent: :destroy

  # Só condition usa `store`: columns/group_by/aggregations são arrays em jsonb,
  # e `store` converteria silenciosamente um Array em {}.
  store :condition

  validates :name, presence: true
  validates :object, presence: true, inclusion: { in: OBJECTS }
  validates :visibility, presence: true, inclusion: { in: VISIBILITIES }
  validate :groups_present_for_group_visibility
  validate :enabled_filters_are_known_attributes

  scope :active, -> { where(active: true) }

  # Modelos que este usuário pode enxergar.
  #
  # Deliberadamente não confia em `Group.all` para o nível de grupo: usa os
  # grupos em que o usuário tem acesso de leitura, para que perder acesso a um
  # grupo também esconda os relatórios daquele grupo.
  def self.visible_to(user)
    return none if !user

    reports = active.left_outer_joins(:groups).distinct

    reports.where(visibility: 'global')
      .or(reports.where(created_by_id: user.id))
      .or(reports.where(visibility: 'group', groups: { id: visible_group_ids(user) }))
  end

  def self.visible_group_ids(user)
    return Group.pluck(:id) if user.permissions?('admin')

    user.group_ids_access('read')
  end

  def visible_to?(user)
    return false if !user
    return true if created_by_id == user.id
    return true if visibility == 'global'
    return false if visibility != 'group'

    group_ids.intersect?(self.class.visible_group_ids(user))
  end

  # Somente quem criou (ou um admin) mexe no modelo. Compartilhar um relatório
  # dá acesso de leitura, não de edição.
  def editable_by?(user)
    return false if !user
    return true if user.permissions?('admin')

    created_by_id == user.id
  end

  def target_class
    object.constantize
  end

  # O componente de atributos do Zammad (checkboxTicketAttributes, o mesmo da
  # Visão Geral) entrega o nome sem o sufixo de relação: "state" em vez de
  # "state_id". Aqui isso volta para o nome real da coluna, para colunas e
  # filtros salvos pela interface valerem no banco.
  #
  # Devolve nil se não houver coluna correspondente, para o chamador descartar.
  def self.normalize_attribute(name, klass)
    name = name.to_s
    return name if klass.column_names.include?(name)

    with_id = "#{name}_id"
    return with_id if klass.column_names.include?(with_id)

    nil
  end

  def normalize_attributes(names)
    Array.wrap(names).filter_map { |name| self.class.normalize_attribute(name, target_class) }
  end

  private

  def groups_present_for_group_visibility
    return if visibility != 'group'
    return if groups.present? || group_ids.present?

    errors.add(:groups, __('At least one group is required to share a report with a group.'))
  end

  # Filtro habilitado precisa corresponder a uma coluna real do objeto: a tela
  # de visualização os transforma em condição de consulta, e um nome inválido só
  # apareceria como erro de SQL no momento de filtrar.
  def enabled_filters_are_known_attributes
    invalid = Array.wrap(enabled_filters).reject do |name|
      self.class.normalize_attribute(name, target_class)
    end
    return if invalid.blank?

    errors.add(:enabled_filters, format(__('Unknown attribute(s): %s'), invalid.join(', ')))
  end
end
