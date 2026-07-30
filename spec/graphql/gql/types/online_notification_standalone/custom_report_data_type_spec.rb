# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: relatório personalizado.

require 'rails_helper'

# OnlineNotificationStandalone.data é non-null. Sem o ramo 'custom_report' no
# resolver, ou sem o tipo na union, a consulta de notificações inteira falha —
# não só a notificação do relatório. Daí a cobertura própria.
RSpec.describe Gql::Types::OnlineNotificationStandalone::CustomReportDataType, type: :graphql do
  let(:user) { create(:agent) }

  let(:query) do
    <<~QUERY
      query onlineNotifications {
        onlineNotifications {
          edges {
            node {
              metaObject {
                ... on OnlineNotificationStandalone {
                  data {
                    __typename
                    ... on OnlineNotificationStandaloneCustomReportData {
                      customReportId
                      status
                    }
                  }
                }
              }
            }
          }
        }
      }
    QUERY
  end

  context 'with a custom report notification', authenticated_as: :user do
    before do
      standalone = create(:online_notification_standalone, :custom_report)
      create(:online_notification, user: user, o: standalone, type_name: 'custom_report')

      gql.execute(query)
    end

    it 'resolves the payload instead of returning null' do
      expect(gql.result.nodes.first['metaObject']['data'])
        .to include('__typename' => 'OnlineNotificationStandaloneCustomReportData',
                    'status'     => 'succeeded')
    end

    # gql.result.error só serve para o caso em que se ESPERA erro; aqui a
    # verificação é sobre o payload cru não trazer nenhum.
    it 'does not error' do
      expect(gql.result.payload['errors']).to be_nil
    end
  end
end
