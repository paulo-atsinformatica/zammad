# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Controllers::PauseTypesControllerPolicy < Controllers::ApplicationControllerPolicy
  def index?
    pause_read_access?
  end

  def show?
    pause_read_access?
  end

  def search?
    pause_read_access?
  end

  def create?
    user.permissions?('admin.pause_type')
  end

  def update?
    user.permissions?('admin.pause_type')
  end

  def destroy?
    user.permissions?('admin.pause_type')
  end

  private

  def pause_read_access?
    user.permissions?(['admin.pause_type', 'user.pause_control'])
  end
end

