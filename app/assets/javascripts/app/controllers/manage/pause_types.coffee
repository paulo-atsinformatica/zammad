class ManagePauseTypes extends App.ControllerSubContent
  @requiredPermission: 'admin.pause_type'
  header: __('Tipos de Pausa')
  constructor: ->
    super

    @genericController = new App.ControllerGenericIndex(
      el: @el
      id: @id
      genericObject: 'PauseType'
      defaultSortBy: 'name'
      searchBar: true
      searchQuery: @search_query
      pageData:
        home: 'pause_types'
        object: __('Pause Type')
        objects: __('Pause Types')
        searchPlaceholder: __('Search for pause types')
        pagerAjax: true
        pagerBaseUrl: '#manage/pause_types/'
        pagerSelected: ( @page || 1 )
        pagerPerPage: 50
        navupdate: '#manage/pause_types'
        buttons: [
          { name: __('New Pause Type'), 'data-type': 'new', class: 'btn--success' }
        ]
      container: @el.closest('.content')
      veryLarge: true
    )

  show: (params) =>
    for key, value of params
      if key isnt 'el' && key isnt 'shown' && key isnt 'match'
        @[key] = value

    @genericController.paginate(@page || 1, params)

App.Config.set('PauseTypes', { prio: 2400, name: __('Tipos de Pausa'), parent: '#manage', target: '#manage/pause_types', controller: ManagePauseTypes, permission: ['admin.pause_type'] }, 'NavBarAdmin')



