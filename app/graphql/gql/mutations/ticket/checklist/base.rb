<<<<<<< HEAD
# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::Checklist::Base < BaseMutation
    include Gql::Concerns::EnsuresChecklistFeatureActive

    description 'Base class for checklist mutations.'

    def self.authorize(_obj, ctx)
      ensure_checklist_feature_active!
      ctx.current_user.permissions?(['ticket.agent'])
    end
  end
end
=======
# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::Checklist::Base < BaseMutation
    description 'Base class for checklist mutations.'

    requires_enabled_setting 'checklist', error_message: __('The checklist feature is not active')
    requires_permission 'ticket.agent'
  end
end
>>>>>>> upstream/develop
