class Controllers::PauseIndicatorsActionsControllerPolicy < Controllers::ApplicationControllerPolicy

  def permitted?
    user.permissions?(['report.pause_indicators', 'user.pause_control'])
  end

  def login?
    permitted?
  end

  def logout?
    permitted?
  end

  def start_pause?
    permitted?
  end

  def end_pause?
    permitted?
  end

  def set_state?
    permitted?
  end
end

