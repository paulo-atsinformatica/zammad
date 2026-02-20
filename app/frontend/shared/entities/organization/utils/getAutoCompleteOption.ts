<<<<<<< HEAD
// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { Organization } from '#shared/graphql/types.ts'
import { ensureGraphqlId } from '#shared/graphql/utils.ts'

export const getAutoCompleteOption = (organization: Partial<Organization>) => {
  return {
    label: organization.name,
    value:
      organization.internalId ||
      (organization.id ? ensureGraphqlId('Organization', organization.id) : null),
    organization,
  }
}
=======
// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { Organization } from '#shared/graphql/types.ts'
import { getIdFromGraphQLId } from '#shared/graphql/utils.ts'

export const getAutoCompleteOption = (organization: Partial<Organization>) => {
  return {
    label: organization.name,
    value: organization.internalId || getIdFromGraphQLId(organization.id as string),
    organization,
  }
}
>>>>>>> upstream/develop
