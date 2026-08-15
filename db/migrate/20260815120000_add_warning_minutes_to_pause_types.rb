# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: aviso de fim de pausa.

class AddWarningMinutesToPauseTypes < ActiveRecord::Migration[8.0]
  # Sem o guard de `system_init_done` usado nas outras migrations ATS: aquele
  # existe para migrations que reaplicam DADOS que o seed já cria numa
  # instalação nova. Esta cria COLUNA, e pular numa instalação nova deixaria o
  # schema incompleto.
  def up
    return if column_exists?(:pause_types, :warning_minutes)

    # Nullable e sem default: null significa "não avisar", que é o
    # comportamento de antes desta migration. Quem quiser aviso preenche o
    # campo no tipo de pausa.
    add_column :pause_types, :warning_minutes, :integer, null:    true,
                                                         comment: 'Minutes before the time limit to warn the user; null disables the warning'

    PauseType.reset_column_information
  end

  def down
    return if !column_exists?(:pause_types, :warning_minutes)

    remove_column :pause_types, :warning_minutes

    PauseType.reset_column_information
  end
end
