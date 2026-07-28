# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module ChecksCoreWorkflow
  extend ActiveSupport::Concern

  # keep in sync with App.Model@_validate_is_empty
  EMPTY_VALUES = [nil, {}, [], [''], ''].freeze

  included do
    before_create :validate_workflows
    before_update :validate_workflows

    attr_accessor :screen
  end

  private

  class_methods do

    # defines the screens which core workflow executes
    def core_workflow_screens(*screens)
      @core_workflow_screens ||= screens
    end

    # defines the screens which are configurable via admin interface
    def core_workflow_admin_screens(*screens)
      @core_workflow_admin_screens ||= screens
    end
  end

  def validate_workflows
    return if !screen
    return if !UserInfo.current_user_id

    perform_result = CoreWorkflow.perform(payload: {
                                            'event'      => 'core_workflow',
                                            'request_id' => 'ChecksCoreWorkflow.validate_workflows',
                                            'class_name' => self.class.to_s,
                                            'screen'     => screen,
                                            'params'     => attributes
                                          }, user: UserInfo.current_user, assets: false)

    check_restrict_values(perform_result)
    check_mandatory(perform_result)
  end

  def check_restrict_values(perform_result)
    changes.each_key do |key|
      next if perform_result[:restrict_values][key].blank?
      next if self[key].blank?
      next if restricted_value?(perform_result, key)

      raise Exceptions::ApplicationModel.new(self, core_workflow_error(__('The value selected for "%s" is not allowed by the current workflow rules.'), key))
    end
  end

  def restricted_value?(perform_result, key)
    if self[key].is_a?(Array)
      (self[key].map(&:to_s) - perform_result[:restrict_values][key].map(&:to_s)).blank?
    else
      perform_result[:restrict_values][key].any? { |value| value.to_s == self[key].to_s }
    end
  end

  # Customização ATS: as mensagens originais eram inglês hardcoded com o nome
  # cru da coluna interpolado no meio ("Invalid value 'x' for field
  # 'state_id'!"). Como a interpolação acontece antes de a mensagem chegar ao
  # frontend, não sobrava msgid para casar e traduzir por override era
  # impossível — por isso a tradução é feita aqui, no servidor.
  # Também troca o nome da coluna pelo rótulo do campo, que é o que o usuário
  # vê na tela.
  def core_workflow_error(template, key)
    user   = UserInfo.current_user
    locale = user.try(:locale) || Setting.get('locale_default') || 'en-us'

    Translation.translate(locale, template, core_workflow_field_label(key, user, locale))
  end

  def core_workflow_field_label(key, user, locale)
    attribute = ObjectManager::Object
      .new(self.class.to_s)
      .attributes(user, skip_permission: user.nil?)
      .find { |item| item[:name] == key.to_s }

    return key.to_s if attribute.blank? || attribute[:display].blank?

    Translation.translate(locale, attribute[:display].to_s)
  # O rótulo é só cosmético: se a busca falhar (classe sem ObjectManager,
  # atributo removido), cai no nome da coluna em vez de transformar um erro de
  # validação legível num 500.
  rescue => e
    Rails.logger.debug { "Could not resolve display label for '#{key}': #{e.message}" }
    key.to_s
  end

  def check_mandatory(perform_result)
    perform_result[:mandatory].each_key do |key|
      next if field_visible?(perform_result, key)
      next if !field_mandatory?(perform_result, key)
      next if !column_empty?(key)
      next if column_default?(key)

      raise Exceptions::ApplicationModel.new(self, core_workflow_error(__('The field "%s" is required.'), key))
    end
  end

  def field_visible?(perform_result, key)
    %w[hide remove].include?(perform_result[:visibility][key])
  end

  def field_mandatory?(perform_result, key)
    perform_result[:mandatory][key]
  end

  def column_empty?(key)
    EMPTY_VALUES.include?(self[key])
  end

  def column_default?(key)
    EMPTY_VALUES.exclude?(self.class.column_defaults[key])
  end
end
