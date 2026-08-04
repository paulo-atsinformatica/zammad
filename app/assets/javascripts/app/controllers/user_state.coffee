class UserState extends App.ControllerSubContent
  header: __('Estado')
  constructor: ->
    super
    @render()

  show: (params) ->
    @render()

  render: ->
    currentUser = App.User.current()
    currentState = currentUser?.current_state || 'offline'
    
    # Get state color
    stateColor = switch currentState
      when 'offline' then '#999999'
      when 'online' then '#38AE6A'
      when 'pause' then '#FFA500'
      else '#999999'
    
    @html App.view('navigation/user_state')(
      currentState: currentState
      pauseTypes: []
      stateColor: stateColor
    )

App.Config.set('user_state', UserState, 'Routes')



