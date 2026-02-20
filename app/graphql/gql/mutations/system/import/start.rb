<<<<<<< HEAD
# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class System::Import::Start < BaseMutation
    description 'Start the system import process'

    field :success, Boolean, null: false, description: 'Was the start successful?'

    def self.authorize(...)
      true
    end

    def resolve
      Service::System::Import::Run.new.execute

      { success: true }
    end
  end
end
=======
# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class System::Import::Start < BaseMutation
    description 'Start the system import process'

    field :success, Boolean, null: false, description: 'Was the start successful?'

    allow_public_access!

    def resolve
      Service::System::Import::Run.new.execute

      { success: true }
    end
  end
end
>>>>>>> upstream/develop
