<<<<<<< HEAD
# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class AppMaintenance < BaseSubscription

    description 'Application update/change events'

    broadcastable true

    field :type, Gql::Types::Enum::AppMaintenanceTypeType, description: 'Maintenance type, may trigger actions in the front end'

    def self.authorize(...)
      true # This subscription should be available for all (including unauthenticated) users.
    end

    def update
      object
    end
  end
end
=======
# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class AppMaintenance < BaseSubscription

    description 'Application update/change events'

    broadcastable true

    field :type, Gql::Types::Enum::AppMaintenanceTypeType, description: 'Maintenance type, may trigger actions in the front end'

    allow_public_access!

    def update
      object
    end
  end
end
>>>>>>> upstream/develop
