# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Translation::Upsert < Service::Base
  attr_reader :locale, :source, :target

  def initialize(locale:, source:, target:)
    @locale = locale
    @source = source
    @target = target
  end

  def execute
    translation = Translation.find_source(locale, source)

    if translation
      translation.update!(target: target)
      return translation
    end

    # Em installs reais, a tabela translations exige created_by_id/updated_by_id NOT NULL.
    # Como este service roda fora do contexto de um usuário logado (runner/init),
    # atribuimos os registros ao usuário de sistema (id 1) ou, em último caso, ao
    # primeiro usuário existente.
    system_user_id = User.where(id: 1).pick(:id) || User.order(:id).limit(1).pick(:id)

    Translation.create!(
      locale:                       locale,
      source:                       source,
      target:                       target,
      is_synchronized_from_codebase: false,
      created_by_id:                system_user_id,
      updated_by_id:                system_user_id,
    )
  end
end
