do ->
  STORAGE_KEY = 'public_pause_indicators_filters_v1'
  POLLING_FALLBACK_MS = 5000
  POLLING_SAFETY_MS = 20000
  refreshTimer = null
  safetyTimer = null
  durationTimer = null
  eventSource = null
  isFirstLoad = true

  loadFilters = ->
    try
      raw = window.localStorage.getItem(STORAGE_KEY)
      return {} unless raw
      JSON.parse(raw) or {}
    catch error
      {}

  saveFilters = (filters) ->
    try
      window.localStorage.setItem(STORAGE_KEY, JSON.stringify(filters))
    catch error
      return

  setSelectValues = (select, values) ->
    return unless select?
    for option in select.options
      option.selected = values.indexOf(option.value) isnt -1

  getMultiSelectValues = (select) ->
    return [] unless select?
    values = []
    for option in select.options when option.selected and option.value
      values.push(option.value)
    values

  currentFilters = ->
    usersSelect  = document.getElementById('js-filter-users')
    teamsSelect  = document.getElementById('js-filter-teams')
    loggedSelect = document.getElementById('js-filter-logged')

    users:  getMultiSelectValues(usersSelect)
    teams:  getMultiSelectValues(teamsSelect)
    logged: if loggedSelect? then loggedSelect.value else ''

  applyFiltersToUI = (filters) ->
    usersSelect  = document.getElementById('js-filter-users')
    teamsSelect  = document.getElementById('js-filter-teams')
    loggedSelect = document.getElementById('js-filter-logged')

    if filters.users?
      setSelectValues(usersSelect, (String(id) for id in filters.users))
    if filters.teams?
      setSelectValues(teamsSelect, (String(id) for id in filters.teams))
    if filters.logged? and filters.logged isnt '' and loggedSelect?
      loggedSelect.value = filters.logged

  clearFilters = ->
    saveFilters({})
    usersSelect  = document.getElementById('js-filter-users')
    teamsSelect  = document.getElementById('js-filter-teams')
    loggedSelect = document.getElementById('js-filter-logged')
    setSelectValues(usersSelect, []) if usersSelect?
    setSelectValues(teamsSelect, []) if teamsSelect?
    loggedSelect.value = '' if loggedSelect?
    loadData()

  formatSeconds = (sec) ->
    sec = Math.max(0, Math.floor(sec))
    h   = Math.floor(sec / 3600)
    m   = Math.floor((sec % 3600) / 60)
    s   = sec % 60
    pad = (n) -> if n < 10 then "0#{n}" else String(n)
    if h > 0 then "#{pad(h)}:#{pad(m)}:#{pad(s)}" else "#{pad(m)}:#{pad(s)}"

  # baseSeconds é o acumulado que já veio do servidor; startedAt marca o início
  # do trecho que ainda está correndo. A contagem de tempo de atendimento passa
  # por várias pausas, então sem o acumulado o cronômetro voltaria do zero a
  # cada retomada.
  formatDuration = (startedAt, baseSeconds = 0) ->
    base = Number(baseSeconds) or 0
    return formatSeconds(base) unless startedAt
    started = new Date(startedAt)
    return formatSeconds(base) if isNaN(started.getTime())
    now = new Date()
    formatSeconds(base + Math.floor((now - started) / 1000))

  buildIndicatorCell = (entry) ->
    span = document.createElement('span')
    span.className = 'pause-indicator'

    if !entry.logged_in
      span.className += ' pause-indicator--logged-out'
      span.title = 'Deslogado'
    else if entry.in_pause
      span.className += ' pause-indicator--pause'
      span.title = 'Em pausa'
    else if entry.state is 'online'
      span.className += ' pause-indicator--online'
      span.title = 'Online'
    else
      span.className += ' pause-indicator--offline'
      span.title = 'Offline'

    td = document.createElement('td')
    td.className = 'pause-indicators-col-indicator'
    td.appendChild(span)
    td

  renderTable = (data) ->
    tbody = document.querySelector('.js-public-pause-body')
    return unless tbody?

    while tbody.firstChild
      tbody.removeChild(tbody.firstChild)

    unless data?.entries? and data.entries.length > 0
      trEmpty = document.createElement('tr')
      tdEmpty = document.createElement('td')
      tdEmpty.colSpan = 10
      tdEmpty.textContent = 'Nenhum registro encontrado'
      trEmpty.appendChild(tdEmpty)
      tbody.appendChild(trEmpty)
      return

    data.entries.forEach (entry) ->
      tr = document.createElement('tr')
      tr.className = 'pause-indicators-row'

      # Destaque da linha inteira. Em pausa vence offline: quem está em pausa
      # também aparece com state 'pause', e é a informação mais específica.
      if !entry.logged_in
        tr.className += ' pause-indicators-row--logged-out'
      else if entry.in_pause
        tr.className += ' pause-indicators-row--pause'
      else if entry.state isnt 'online'
        tr.className += ' pause-indicators-row--offline'

      tr.setAttribute('data-state', entry.state or '')
      tr.setAttribute('data-in-pause', if entry.in_pause then 'true' else 'false')
      tr.setAttribute('data-pause-started-at', entry.pause_started_at or '')

      tr.appendChild(buildIndicatorCell(entry))

      tdName = document.createElement('td')
      tdName.textContent = entry.name or '-'
      tr.appendChild(tdName)

      tdStatus = document.createElement('td')
      tdStatus.textContent = entry.status or '-'
      tr.appendChild(tdStatus)

      tdInPause = document.createElement('td')
      tdInPause.textContent = if entry.in_pause then 'Sim' else 'Não'
      tr.appendChild(tdInPause)

      tdDuration = document.createElement('td')
      tdDuration.className = 'js-pause-duration-cell'
      if entry.in_pause and entry.pause_started_at
        tdDuration.setAttribute('data-started-at', entry.pause_started_at)
        tdDuration.textContent = formatDuration(entry.pause_started_at)
      else
        tdDuration.setAttribute('data-started-at', '')
        tdDuration.textContent = '-'
      tr.appendChild(tdDuration)

      tdLogged = document.createElement('td')
      tdLogged.textContent = if entry.logged_in then 'Sim' else 'Não'
      tr.appendChild(tdLogged)

      tdPauseName = document.createElement('td')
      tdPauseName.textContent = entry.pause_name or '-'
      tr.appendChild(tdPauseName)

      # Atendimento em curso. O cronômetro é montado igual ao de pausa: o
      # servidor manda acumulado + início do trecho corrente, e o timer local
      # soma segundo a segundo.
      tdTracking = document.createElement('td')
      tdTracking.className = 'js-tracking-duration-cell'
      if entry.tracking_started_at
        tdTracking.setAttribute('data-started-at', entry.tracking_started_at)
        tdTracking.setAttribute('data-base-seconds', String(entry.tracking_total_seconds or 0))
        tdTracking.textContent = formatDuration(entry.tracking_started_at, entry.tracking_total_seconds)
      else
        tdTracking.setAttribute('data-started-at', '')
        tdTracking.setAttribute('data-base-seconds', '0')
        tdTracking.textContent = '-'
      tr.appendChild(tdTracking)

      tdTicket = document.createElement('td')
      tdTicket.textContent = entry.tracking_ticket_number or '-'
      tr.appendChild(tdTicket)

      tdOrganization = document.createElement('td')
      tdOrganization.textContent = entry.tracking_organization or '-'
      tr.appendChild(tdOrganization)

      tbody.appendChild(tr)

  renderFilters = (data, restoredFilters) ->
    usersSelect = document.getElementById('js-filter-users')
    teamsSelect = document.getElementById('js-filter-teams')

    if usersSelect? and data?.agents?
      usersSelect.innerHTML = ''
      data.agents.forEach (agent) ->
        opt = document.createElement('option')
        opt.value = String(agent.id)
        opt.textContent = agent.name or "##{agent.id}"
        usersSelect.appendChild(opt)

    if teamsSelect? and data?.teams?
      teamsSelect.innerHTML = ''
      data.teams.forEach (team) ->
        opt = document.createElement('option')
        opt.value = String(team.id)
        opt.textContent = team.name or "##{team.id}"
        teamsSelect.appendChild(opt)

    applyFiltersToUI(restoredFilters)

  updateLastUpdated = ->
    el = document.querySelector('.js-last-updated')
    return unless el?
    now  = new Date()
    time = now.toLocaleTimeString()
    el.textContent = "Atualizado em #{time}"

  buildQueryString = (filters) ->
    params = []
    (filters.users or []).forEach (id) ->
      params.push("user_ids[]=#{encodeURIComponent(id)}")
    (filters.teams or []).forEach (value) ->
      params.push("equipes[]=#{encodeURIComponent(value)}")
    if filters.logged
      params.push("logged_state=#{encodeURIComponent(filters.logged)}")
    params.join('&')

  loadData = ->
    filters = currentFilters()
    saveFilters(filters)

    qs  = buildQueryString(filters)
    qs += (if qs then '&' else '') + "_=#{Date.now()}"
    url = '/api/v1/public_pause_indicators'
    url += "?#{qs}"

    window.fetch(url, { credentials: 'same-origin', cache: 'no-store' })
      .then (response) -> response.json()
      .then (data) ->
        if isFirstLoad
          renderFilters(data, filters)
          isFirstLoad = false
        renderTable(data)
        updateLastUpdated()
      .catch ->
        # mantém estado atual em caso de erro
        return

  updateAllDurations = ->
    cells = document.querySelectorAll('.js-pause-duration-cell, .js-tracking-duration-cell')
    return unless cells.length
    for cell in cells
      startedAt = cell.getAttribute('data-started-at')
      unless startedAt
        cell.textContent = '-'
        continue
      # Só a célula de atendimento traz acumulado; a de pausa conta do zero.
      base = Number(cell.getAttribute('data-base-seconds')) or 0
      cell.textContent = formatDuration(startedAt, base)

  startDurationTimer = ->
    return if durationTimer?
    durationTimer = window.setInterval(updateAllDurations, 1000)

  startPollingFallback = ->
    return if refreshTimer?
    loadData()
    refreshTimer = window.setInterval(loadData, POLLING_FALLBACK_MS)

  startSafetyPolling = ->
    return if safetyTimer?
    safetyTimer = window.setInterval(loadData, POLLING_SAFETY_MS)

  startRealtime = ->
    startSafetyPolling()
    startDurationTimer()
    if typeof window.EventSource is 'function'
      if eventSource?
        eventSource.close()
        eventSource = null
      streamUrl = "#{window.location.origin}/api/v1/public_pause_indicators/stream"
      try
        eventSource = new window.EventSource(streamUrl)
        eventSource.onmessage = ->
          loadData()
        eventSource.onerror = ->
          # Guard: só age se eventSource ainda não foi encerrado por chamada anterior
          # (onerror pode disparar múltiplas vezes antes do close() surtir efeito)
          return unless eventSource?
          eventSource.close()
          eventSource = null
          startPollingFallback()
      catch err
        startPollingFallback()
    else
      startPollingFallback()

  setup = ->
    container = document.querySelector('.public-pause-indicators')
    return unless container?

    restoredFilters = loadFilters()
    applyFiltersToUI(restoredFilters)

    usersSelect  = document.getElementById('js-filter-users')
    teamsSelect  = document.getElementById('js-filter-teams')
    loggedSelect = document.getElementById('js-filter-logged')

    onFilterChange = -> loadData()

    usersSelect?.addEventListener('change', onFilterChange)
    teamsSelect?.addEventListener('change', onFilterChange)
    loggedSelect?.addEventListener('change', onFilterChange)

    clearBtn = document.getElementById('js-clear-filters')
    clearBtn?.addEventListener('click', clearFilters)

    loadData()
    startRealtime()
    startDurationTimer()

  if document.readyState is 'loading'
    document.addEventListener 'DOMContentLoaded', setup
  else
    setup()

