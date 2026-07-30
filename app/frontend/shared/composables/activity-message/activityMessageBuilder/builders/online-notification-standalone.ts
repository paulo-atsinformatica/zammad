// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type {
  OnlineNotificationStandalone,
  OnlineNotificationStandaloneBulkJobData,
  // Customização ATS: relatório personalizado.
  OnlineNotificationStandaloneCustomReportData,
  OnlineNotificationStandaloneKbAnswerGenerationFailedData,
} from '#shared/graphql/types.ts'
import { i18n } from '#shared/i18n.ts'

import type { ActivityMessageBuilder } from '../types.ts'

// No links for standalone notifications, as they are not related to a specific object.
const path = () => undefined

const messageText = (
  _type: string,
  _authorName: string,
  metaObject?: OnlineNotificationStandalone,
): Maybe<string> => {
  if (!metaObject) {
    return i18n.t('You can no longer see the standalone online notification.')
  }

  switch (metaObject.data.__typename) {
    case 'OnlineNotificationStandaloneBulkJobData': {
      const data = metaObject.data as OnlineNotificationStandaloneBulkJobData
      return i18n.t(
        'Bulk action completed for |%s| ticket(s): %s successful, %s failed',
        data.total,
        data.total - data.failedCount,
        data.failedCount,
      )
    }
    case 'OnlineNotificationStandaloneKbAnswerGenerationFailedData': {
      const data = metaObject.data as OnlineNotificationStandaloneKbAnswerGenerationFailedData
      return i18n.t(
        'Failed to generate knowledge base draft for "%s": %s',
        data.ticketTitle,
        data.errorMessage,
      )
    }
    // Customização ATS: relatório personalizado.
    case 'OnlineNotificationStandaloneCustomReportData': {
      const data = metaObject.data as OnlineNotificationStandaloneCustomReportData
      if (data.status === 'failed') return i18n.t('Custom report generation failed.')
      return i18n.t('Your custom report is ready to download.')
    }
    default:
      return null
  }
}

export default <ActivityMessageBuilder>{
  messageText,
  path,
  model: 'OnlineNotificationStandalone',
}
