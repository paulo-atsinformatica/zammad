class App.PauseType extends App.Model
  @configure 'PauseType', 'name', 'time_limit', 'warning_minutes', 'active', 'updated_at'
  @extend Spine.Model.Ajax
  @url: @apiPath + '/pause_types'

  @configure_attributes = [
    { name: 'name',        display: __('Name'),         tag: 'input',    type: 'text',     limit: 100, null: false },
    { name: 'time_limit',  display: __('Time Limit (minutes)'), tag: 'input',    type: 'number',   null: false, default: 0, note: __('Set to 0 for unlimited') },
    { name: 'warning_minutes', display: __('Warn before the end (minutes)'), tag: 'input', type: 'number', null: true, note: __('Leave empty to disable the warning. Must be smaller than the time limit.') },
    { name: 'active',      display: __('Active'),       tag: 'boolean',  null: false, default: true },
    { name: 'created_by_id', display: __('Created by'), relation: 'User', readonly: 1 },
    { name: 'created_at',    display: __('Created at'), tag: 'datetime',  readonly: 1 },
    { name: 'updated_by_id', display: __('Updated by'), relation: 'User', readonly: 1 },
    { name: 'updated_at',    display: __('Updated at'), tag: 'datetime',  readonly: 1 },
  ]

  @configure_overview = [
    'name', 'time_limit', 'warning_minutes', 'active', 'updated_at'
  ]

  @configure_preview = [
    'name', 'time_limit', 'warning_minutes', 'active', 'created_at'
  ]

  uiUrl: ->
    "#manage/pause_types/#{@id}"

  icon: ->
    'pause'


