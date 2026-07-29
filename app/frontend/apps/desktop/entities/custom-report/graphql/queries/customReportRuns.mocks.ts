import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './customReportRuns.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockCustomReportRunsQuery(defaults: Mocks.MockDefaultsValue<Types.CustomReportRunsQuery, Types.CustomReportRunsQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.CustomReportRunsDocument, defaults)
}

export function waitForCustomReportRunsQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.CustomReportRunsQuery>(Operations.CustomReportRunsDocument)
}

export function mockCustomReportRunsQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.CustomReportRunsDocument, message, extensions);
}
