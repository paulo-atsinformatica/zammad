class App.GlobalSearch extends App.Controller
  ajaxCount: 0
  constructor: ->
    super
    @searchResultCache = {}
    @lastParams = undefined
    @apiPath = App.Config.get('api_path')
    @ajaxId = "search-#{Math.floor( Math.random() * 999999 )}"
    # Bumped on every new search and on close(), so a response for a search that
    #   has since been superseded or closed can be told apart from the current one.
    @searchGeneration = 0

  search: (params) =>
    query = params.query
    @searchGeneration += 1
    requestGeneration = @searchGeneration

    cacheKey = @searchResultCacheKey(query, params)

    # use cache for search result
    currentTime = new Date
    if !params.force && @searchResultCache[cacheKey] && @searchResultCache[cacheKey].time > currentTime.setSeconds(currentTime.getSeconds() - 20)
      if @ajaxRequestId
        App.Ajax.abort(@ajaxRequestId)
      @ajaxStart(params)
      @renderTry(@searchResultCache[cacheKey].result, query, params)
      delayCallback = =>
        @ajaxStop(params)
      @delay(delayCallback, 700)
      return

    delayCallback = =>

      @ajaxStart(params)

      delayCallback = ->
        if params.callbackLongerAsExpected
          params.callbackLongerAsExpected()
      @delay(delayCallback, 10000, 'global-search-ajax-longer-as-expected')

      @ajaxRequestId = App.Ajax.request(
        id:   @ajaxId
        type: 'GET'
        url: "#{@apiPath}/search"
        data:
          query: query
          by_object: true
          objects: params.object
          limit: @limit || 10
          offset: params.offset
          order_by: params.orderDirection
          sort_by: params.orderBy
        processData: true
        success: (data, status, xhr) =>
          @clearDelay('global-search-ajax-longer-as-expected')
          App.Collection.loadAssets(data.assets)

          userProfileAccess         = @permissionCheck(App.Config.get('user/profile/:user_id', 'Routes').requiredPermission)
          organizationProfileAccess = @permissionCheck(App.Config.get('organization/profile/:organization_id', 'Routes').requiredPermission)

          result = {}
          for klassName, metadata of data.result
            # user and organization are allowed via API but should not show # up for customers because there are no profile pages for customers
            continue if klassName is 'User' && !userProfileAccess
            continue if klassName is 'Organization' && !organizationProfileAccess

            klass = App[klassName]

            if !klass.find
              App.Log.error('_globalSearchSingleton', "No such model App.#{klassName}")
              continue

            item_objects = []

            for item_id in metadata.object_ids
              item_object = klass.find(item_id)

              if !item_object.searchResultAttributes
                App.Log.error('_globalSearchSingleton', "No such model #{klassName.toLocaleLowerCase()}.searchResultAttributes()")
                continue

              item_objects.push(item_object.searchResultAttributes())

            result[klassName] = { items: item_objects, total_count: metadata.total_count }

          @ajaxStop(params)

          # A newer search (or a close()) superseded this request while it was in
          #   flight - rendering now would reopen/repopulate a dropdown the user
          #   already moved on from.
          return if requestGeneration isnt @searchGeneration

          @loadEconomicGroups(query, result, requestGeneration, params)
        error: =>
          @clearDelay('global-search-ajax-longer-as-expected')
          @ajaxStop(params)
      )
    @delay(delayCallback, params.delay || 1, 'global-search-ajax')

  # Customização ATS: "Grupo Econômico" (Organization#grupoeconomico) não é um
  # model pesquisável de verdade (Models.searchable) - por isso entra como
  # uma seção sintética à parte, buscada num endpoint próprio e mesclada no
  # resultado antes de renderizar, em vez de participar do /search genérico.
  loadEconomicGroups: (query, result, requestGeneration, params) =>
    economicGroupProfileAccess = @permissionCheck(App.Config.get('economic_group/profile/:name', 'Routes').requiredPermission)

    return @renderTry(result, query, params) if !economicGroupProfileAccess

    App.Ajax.request(
      id:          "#{@ajaxId}-economic-groups"
      type:        'GET'
      url:         "#{@apiPath}/economic_groups/search"
      data:
        query: query
      processData: true
      success: (groups) =>
        return if requestGeneration isnt @searchGeneration

        if groups && groups.length > 0
          result['EconomicGroup'] =
            items: (
              for group in groups
                display: "#{group.name} (#{group.count})"
                id:      group.name
                class:   'economic-group'
                url:     "#economic_group/profile/#{encodeURIComponent(group.name)}"
                icon:    'economic-group'
            )
            total_count: groups.length

        @renderTry(result, query, params)
      error: =>
        @renderTry(result, query, params)
    )

  ajaxStart: (params) =>
    @ajaxCount++
    if params.callbackStart
      params.callbackStart()

  ajaxStop: (params) =>
    @ajaxCount--
    if @ajaxCount == 0 && params.callbackStop
      params.callbackStop()

  renderTry: (result, query, params) =>
    cacheKey = @searchResultCacheKey(query, params)

    if query
      if _.isEmpty(result)
        if params.callbackNoMatch
          params.callbackNoMatch()
      else
        if params.callbackMatch
          params.callbackMatch()

      # if result hasn't changed, do not rerender
      if !params.force && @lastParams is params && @searchResultCache[cacheKey]
        diff = difference(@searchResultCache[cacheKey].result, result)
        if _.isEmpty(diff)
          return

      @lastParams = params

      # cache search result
      @searchResultCache[cacheKey] =
        result: result
        time: new Date

    @render(result, params)

  searchResultCacheKey: (query, params) ->
    "#{query}-#{params.object}-#{params.offset}-#{params.orderDirection}-#{params.orderBy}"

  close: =>
    if @ajaxRequestId
      App.Ajax.abort(@ajaxRequestId)
    @lastParams = undefined
    @searchGeneration += 1

    # cancel pending/in-flight search so a late response can not re-render after close (#4786)
    @clearDelay('global-search-ajax')
    @clearDelay('global-search-ajax-longer-as-expected')
    if @ajaxRequestId
      App.Ajax.abort(@ajaxRequestId)
      @ajaxRequestId = undefined
