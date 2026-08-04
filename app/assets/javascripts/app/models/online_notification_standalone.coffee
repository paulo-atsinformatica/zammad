class App.OnlineNotificationStandalone extends App.Model
  @configure 'OnlineNotificationStandalone', 'kind', 'data'

  activityMessage: (item) ->
    return if !item
    return if !item.created_by

    switch item.type
      when 'bulk_job'
        { total, failed_count } = item.objectNative?.data
        return if _.isUndefined(total) or _.isUndefined(failed_count)
        return App.i18n.translateContent('Bulk action completed for |%s| ticket(s): %s successful, %s failed', total, total - failed_count, failed_count)
      when 'kb_answer_generation_failed'
        { error_message, ticket_title } = item.objectNative?.data
        return App.i18n.translateContent('Failed to generate knowledge base draft for "%s": %s', ticket_title, error_message)
      # Customização ATS: relatório personalizado.
      when 'custom_report'
        { status } = item.objectNative?.data
        if status is 'failed'
          return App.i18n.translateContent('Custom report generation failed.')
        return App.i18n.translateContent('Your custom report is ready to download.')
      else
        return "Unknown action for (#{@objectDisplayName()}/#{item.type}), extend activityMessage() of model."

  uiUrl: (item) ->
    # Customização ATS: leva direto ao relatório para o usuário baixar.
    return '#report/custom' if item?.type is 'custom_report'

    undefined
