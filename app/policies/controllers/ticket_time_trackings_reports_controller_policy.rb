# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Controllers::TicketTimeTrackingsReportsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('report')
end



