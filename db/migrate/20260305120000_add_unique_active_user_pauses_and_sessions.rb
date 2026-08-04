class AddUniqueActiveUserPausesAndSessions < ActiveRecord::Migration[7.2]
  def change
    # Garante apenas uma pausa ativa por usuário.
    add_index :user_pauses, :user_id,
              name: 'index_user_pauses_on_user_id_active',
              unique: true,
              where: 'ended_at IS NULL'

    # Garante apenas uma sessão ativa de controle de pausa por usuário.
    add_index :user_pause_sessions, :user_id,
              name: 'index_user_pause_sessions_on_user_id_active',
              unique: true,
              where: 'ended_at IS NULL'
  end
end

