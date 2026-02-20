<<<<<<< HEAD
# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::AccessToken::Delete < BaseMutation
    description 'Deletes user access token'

    argument :token_id, GraphQL::Types::ID, loads: Gql::Types::TokenType, description: 'The token to be deleted'
    field :success, Boolean, null: false, description: 'Was the access token deletion successful?'

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?('user_preferences.access_token')
    end

    def authorized?(token:)
      pundit_authorized?(token, :destroy?) && super
    end

    def resolve(token:)
      token.destroy!

      { success: true }
    end
  end
end
=======
# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::AccessToken::Delete < BaseMutation
    description 'Deletes user access token'

    argument :token_id, GraphQL::Types::ID, loads: Gql::Types::TokenType, loads_pundit_method: :destroy?, description: 'The token to be deleted'
    field :success, Boolean, null: false, description: 'Was the access token deletion successful?'

    requires_permission 'user_preferences.access_token'

    def resolve(token:)
      token.destroy!

      { success: true }
    end
  end
end
>>>>>>> upstream/develop
