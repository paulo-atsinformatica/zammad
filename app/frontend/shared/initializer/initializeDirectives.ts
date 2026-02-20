<<<<<<< HEAD
// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/
import { type App } from 'vue'

import tooltip from '#shared/plugins/directives/tooltip/index.ts'

export const initializeTooltipDirective = (app: App) => {
  const { name, directive } = tooltip
  app.directive(name, directive)
}
=======
// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
import { type App } from 'vue'

import tooltip from '#shared/plugins/directives/tooltip/index.ts'

export const initializeTooltipDirective = (app: App) => {
  const { name, directive } = tooltip
  app.directive(name, directive)
}
>>>>>>> upstream/develop
