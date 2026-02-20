<<<<<<< HEAD
// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { useAuthenticationStore } from '#shared/stores/authentication.ts'

import { initializePiniaStore } from './components/renderComponent.ts'

export const mockAuthentication = (authenticated: boolean) => {
  initializePiniaStore()

  const authentication = useAuthenticationStore()
  authentication.authenticated = authenticated
}
=======
// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useAuthenticationStore } from '#shared/stores/authentication.ts'

import { initializePiniaStore } from './components/renderComponent.ts'

export const mockAuthentication = (authenticated: boolean) => {
  initializePiniaStore()

  const authentication = useAuthenticationStore()
  authentication.authenticated = authenticated
}
>>>>>>> upstream/develop
