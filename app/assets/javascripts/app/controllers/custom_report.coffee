# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: configuração dos modelos de relatório personalizado.

# Criar e editar modelos é tarefa de configuração e vive aqui, em Gerenciar. A
# tela de Relatórios (#report/custom) só visualiza e exporta.
class CustomReportManage extends App.ControllerSubContent
  @requiredPermission: 'admin.custom_report'
  header: __('Custom Reports')

  constructor: ->
    super

    @genericController = new App.ControllerGenericIndex(
      el:            @el
      id:            @id
      genericObject: 'CustomReport'
      defaultSortBy: 'name'
      searchBar:     true
      searchQuery:   @search_query
      pageData:
        home:              'custom_reports'
        object:            __('Custom Report')
        objects:           __('Custom Reports')
        searchPlaceholder: __('Search for custom reports')
        pagerAjax:         true
        pagerBaseUrl:      '#manage/custom_reports/'
        pagerSelected:     ( @page || 1 )
        pagerPerPage:      50
        navupdate:         '#custom_reports'
        buttons: [
          { name: __('New Report'), 'data-type': 'new', class: 'btn--success' }
        ]
      container: @el.closest('.content')
    )

  show: (params) =>
    for key, value of params
      if key isnt 'el' && key isnt 'shown' && key isnt 'match'
        @[key] = value

    @genericController.paginate(@page || 1, params)

App.Config.set('CustomReportManage', {
  prio: 2330,
  name: __('Custom Reports'),
  parent: '#manage',
  target: '#manage/custom_reports',
  controller: CustomReportManage,
  permission: ['admin.custom_report']
}, 'NavBarAdmin')
