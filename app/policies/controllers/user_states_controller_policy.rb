class Controllers::UserStatesControllerPolicy < Controllers::ApplicationControllerPolicy
  # Apenas usuários com permissão de controle de pausa podem alterar o estado.
  def set?
    user.permissions?('user.pause_control')
  end

  # Qualquer usuário autenticado pode consultar o próprio estado atual.
  def current?
    true
  end
end

