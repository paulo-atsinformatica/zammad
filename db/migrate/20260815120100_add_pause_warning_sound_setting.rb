# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: aviso de fim de pausa.
#
# Os textos abaixo vão sem __(): migration não marca string traduzível
# (Zammad/ForbidTranslatableMarker). A marcação está em
# db/seeds/ats_settings.rb, e a tradução em i18n/ats.pt-br.po.

class AddPauseWarningSoundSetting < ActiveRecord::Migration[8.0]
  # Em instalação nova quem cria este setting é db/seeds/ats_settings.rb, que
  # não roda de novo aqui. Esta migration existe para as instalações já em
  # produção.
  def up
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Pause warning sound',
      name:        'pause_control_warning_sound',
      area:        'UI::Base',
      description: 'Play a sound when a pause is about to reach its time limit.',
      options:     {
        form: [
          {
            display:   '',
            null:      true,
            name:      'pause_control_warning_sound',
            tag:       'boolean',
            translate: true,
            options:   {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state:       true,
      preferences: {
        permission: ['admin.ui'],
      },
      frontend:    true
    )
  end

  def down
    Setting.find_by(name: 'pause_control_warning_sound')&.destroy
  end
end
