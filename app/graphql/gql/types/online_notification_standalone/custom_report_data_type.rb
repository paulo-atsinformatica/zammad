# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: relatório personalizado.

module Gql::Types::OnlineNotificationStandalone
  class CustomReportDataType < Gql::Types::BaseObject
    description 'Data payload for custom report standalone notifications'

    field :custom_report_id, Integer, null: false, description: 'Report the generation belongs to'
    field :status, String, null: false, description: 'succeeded or failed'
  end
end
