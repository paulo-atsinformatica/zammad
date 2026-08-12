# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: tela de perfil de "Grupo Econômico" (Organization#grupoeconomico).
# Não existe um model/tabela pra isso - é só um agrupamento de Organizations que
# compartilham o mesmo valor nesse campo customizado. Segue o mesmo padrão visual
# de app/assets/javascripts/app/controllers/organization_profile.coffee (lista +
# App.TicketStats), trocando a lista de membros (pessoas) por organizações.
class App.EconomicGroupProfile extends App.Controller
  constructor: (params) ->
    super
    @name = params.name
    @load()

  meta: =>
    url:       @url()
    id:        @name
    head:      @name
    title:     @name
    iconClass: 'economic-group'

  url: =>
    '#economic_group/profile/' + encodeURIComponent(@name)

  show: =>
    @navupdate(url: '#', type: 'menu')

  changed: ->
    false

  load: =>
    @ajax(
      id:          "economic_group_profile_#{@name}"
      type:        'GET'
      url:         "#{@apiPath}/economic_groups/show"
      data:
        name: @name
      processData: true
      success:     (data) =>
        @render(data)
    )

  render: (data) =>
    elLocal = $(App.view('economic_group_profile/index')(
      name:          data.name
      organizations: data.organizations
    ))

    new App.TicketStats(
      el:              elLocal.find('.js-ticket-stats')
      organizationIds: (organization.id for organization in data.organizations)
      init:            true
    )

    @html elLocal

  setPosition: (position) =>
    @$('.profile').scrollTop(position)

  currentPosition: =>
    @$('.profile').scrollTop()

class Router extends App.ControllerPermanent
  @requiredPermission: 'ticket.agent'

  constructor: (params) ->
    super

    @authenticateCheckRedirect()

    clean_params =
      name: decodeURIComponent(params.name)

    App.TaskManager.execute(
      key:        "EconomicGroupProfile-#{clean_params.name}"
      controller: 'EconomicGroupProfile'
      params:     clean_params
      show:       true
    )

App.Config.set('economic_group/profile/:name', Router, 'Routes')
