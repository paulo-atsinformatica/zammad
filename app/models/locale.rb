# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Locale < ApplicationModel
  # Lista mínima quando config/locales.yml está truncado no container (ex.: só "---")
  FALLBACK_LOCALES_YAML = [
    { 'locale' => 'en-us', 'alias' => 'en', 'name' => 'English (United States)', 'active' => true, 'dir' => 'ltr' },
    { 'locale' => 'pt-br', 'alias' => '', 'name' => 'Português (Brasil) - Portuguese (Brazil)', 'active' => true, 'dir' => 'ltr' },
    { 'locale' => 'de-de', 'alias' => 'de', 'name' => 'Deutsch - German', 'active' => true, 'dir' => 'ltr' },
    { 'locale' => 'es-es', 'alias' => 'es', 'name' => 'Español - Spanish', 'active' => true, 'dir' => 'ltr' },
    { 'locale' => 'fr-fr', 'alias' => 'fr', 'name' => 'Français - French', 'active' => true, 'dir' => 'ltr' },
  ].freeze

  has_many :knowledge_base_locales, inverse_of: :system_locale, dependent: :restrict_with_error,
                                    class_name: 'KnowledgeBase::Locale', foreign_key: :system_locale_id

=begin

returns the records of all locales that are to be synchronized

=end

  def self.to_sync
    # read used locales based on env, e. g. export Z_LOCALES='en-us:de-de'
    return Locale.where(active: true, locale: ENV['Z_LOCALES'].split(':')) if ENV['Z_LOCALES']

    return Locale.where(active: true, locale: %w[en-us de-de]) if Rails.env.test?

    Locale.where(active: true)
  end

=begin

sync locales from config/locales.yml

=end

  def self.sync
    file = Rails.root.join('config/locales.yml')
    return false if !File.exist?(file)

    data = YAML.load_file(file)

    if data.nil? || data.is_a?(String)
      Rails.logger.warn "[Locale.sync] config/locales.yml retornou #{data.class.name} (primeiros 200 chars): #{data.to_s.truncate(200)}"
      raw = File.read(file, encoding: 'UTF-8')
      if raw.size > 100
        data = Psych.load(raw)
        Rails.logger.info "[Locale.sync] fallback Psych.load(raw) ok, tipo=#{data.class.name}" if data.is_a?(Array)
      else
        # Arquivo no container truncado. Usar lista mínima para en-us + pt-br (fallback de último recurso).
        Rails.logger.warn "[Locale.sync] arquivo muito curto (#{raw.size} bytes) em #{file}, usando locales mínimos"
        data = FALLBACK_LOCALES_YAML
      end
    end

    if data.is_a?(Hash)
      data = data.fetch('locales', nil)
      return false if data.nil?
    end
    unless data.is_a?(Array) && data.respond_to?(:each)
      Rails.logger.warn "[Locale.sync] config/locales.yml retornou tipo inesperado: #{data.class.name}"
      return false
    end

    to_database(data)
    true
  end

  #  Default system locale
  #
  #  @example
  #    Locale.default
  def self.default
    Setting.get('locale_default') || 'en-us'
  end

  private_class_method def self.to_database(data)
    return unless data.is_a?(Array)

    data.each do |locale|
      exists = Locale.find_by(locale: locale['locale'])
      if exists
        exists.update!(locale.symbolize_keys!)
      else
        Locale.create!(locale.symbolize_keys!)
      end
    rescue => e
      Rails.logger.warn "[Locale.to_database] Falha ao salvar locale '#{locale['locale']}': #{e.message}"
    end
  end

  # Returns ICU language code for usage with TwitterCldr gem
  # Not all locales are supported, so nil can be returned as well!
  #
  # One-liner to filter which locales are not supported by said gem:
  #
  # Locale.all.select { |locale| !TwitterCldr.supported_locale? locale.language_code }
  def cldr_language_code
    case locale
    when 'es-ca' # Catalin, looks like it should be ca-es instead?
      'ca'
    when 'sr-cyrl-rs'
      'sr-Cyrl-ME'
    when 'sr-latn-rs'
      'sr-Latn-ME'
    else
      split = locale.split('-')
      split.second&.upcase!
      joined = split.join('-')

      if TwitterCldr.supported_locale? joined
        joined
      elsif TwitterCldr.supported_locale? split.first
        split.first
      end
    end
  end

  # Returns Postgres database collation names
  #
  # One-liner to verify that locales exist on a given Postgres server:
  #
  # Locale.all.select { |locale| ApplicationModel.connection.execute("SELECT * FROM pg_collation WHERE collname = '#{locale.postgres_collation_name}';").none? }
  def postgres_collation_name
    case locale
    when 'es-ca' # Catalan, looks like it should be ca-es instead?
      'ca-x-icu'
    when 'no-no' # Norwegian, nn vs no?
      'nn-NO-x-icu'
    when 'zh-cn' # China uses simplified
      'zh-Hans-x-icu'
    when 'zh-tw' # Taiwan uses traditional
      'zh-Hant-x-icu'
    when 'sr-cyrl-rs'
      'sr-Cyrl-ME-x-icu'
    when 'sr-latn-rs'
      'sr-Latn-ME-x-icu'
    else
      split = locale.split('-')
      split.second&.upcase!
      "#{split.join('-')}-x-icu"
    end
  end
end
