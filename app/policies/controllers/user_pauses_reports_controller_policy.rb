# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Controllers::UserPausesReportsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!(['report', 'report.user_pauses'])
end



