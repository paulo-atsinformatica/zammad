import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './customReportResults.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockCustomReportResultsQuery(defaults: Mocks.MockDefaultsValue<Types.CustomReportResultsQuery, Types.CustomReportResultsQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.CustomReportResultsDocument, defaults)
}

export function waitForCustomReportResultsQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.CustomReportResultsQuery>(Operations.CustomReportResultsDocument)
}

export function mockCustomReportResultsQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.CustomReportResultsDocument, message, extensions);
}
