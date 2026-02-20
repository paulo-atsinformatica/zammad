<<<<<<< HEAD
// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { keyBy } from 'lodash-es'

import { twoFactorPluginsFiles } from './initializeTwoFactorPlugins.ts'

const plugins = twoFactorPluginsFiles
const pluginListLookup = keyBy(plugins, 'name')

export const useTwoFactorPlugins = () => {
  return {
    twoFactorMethods: plugins,
    twoFactorMethodLookup: pluginListLookup,
  }
}
=======
// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { keyBy } from 'lodash-es'

import { twoFactorPluginsFiles } from './initializeTwoFactorPlugins.ts'

const plugins = twoFactorPluginsFiles
const pluginListLookup = keyBy(plugins, 'name')

export const useTwoFactorPlugins = () => {
  return {
    twoFactorMethods: plugins,
    twoFactorMethodLookup: pluginListLookup,
  }
}
>>>>>>> upstream/develop
