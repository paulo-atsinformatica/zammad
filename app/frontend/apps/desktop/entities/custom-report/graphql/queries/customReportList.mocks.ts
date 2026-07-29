import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './customReportList.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockCustomReportListQuery(defaults: Mocks.MockDefaultsValue<Types.CustomReportListQuery, Types.CustomReportListQueryVariables>) {
  return Mocks.mockGraphQLResult(Operations.CustomReportListDocument, defaults)
}

export function waitForCustomReportListQueryCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.CustomReportListQuery>(Operations.CustomReportListDocument)
}

export function mockCustomReportListQueryError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.CustomReportListDocument, message, extensions);
}
