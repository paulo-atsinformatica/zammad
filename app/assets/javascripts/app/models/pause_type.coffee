class App.PauseType extends App.Model
  @configure 'PauseType', 'name', 'time_limit', 'color', 'active', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/pause_types'

  @configure_attributes = [
    { name: 'name',        display: __('Name'),         tag: 'input',    type: 'text',     limit: 100, null: false },
    { name: 'time_limit',  display: __('Time Limit (minutes)'), tag: 'input',    type: 'number',   null: false, default: 0, note: __('Set to 0 for unlimited') },
    { name: 'color',       display: __('Color (Hex)'), tag: 'input',    type: 'text',     limit: 7,  null: false, default: '#CCCCCC', note: __('Hex color code (e.g., #FF0000)') },
    { name: 'active',      display: __('Active'),       tag: 'boolean',  null: false, default: true },
    { name: 'created_by_id', display: __('Created by'), relation: 'User', readonly: 1 },
    { name: 'created_at',    display: __('Created at'), tag: 'datetime',  readonly: 1 },
    { name: 'updated_by_id', display: __('Updated by'), relation: 'User', readonly: 1 },
    { name: 'updated_at',    display: __('Updated at'), tag: 'datetime',  readonly: 1 },
  ]

  @configure_overview = [
    'name', 'time_limit', 'color', 'active', 'updated_at'
  ]

  @configure_preview = [
    'name', 'time_limit', 'color', 'active', 'created_at'
  ]

  uiUrl: ->
    "#manage/pause_types/#{@id}"

  icon: ->
    'pause'


