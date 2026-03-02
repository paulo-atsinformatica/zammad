# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Controllers::UserPausesControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('user.pause_control')
end
