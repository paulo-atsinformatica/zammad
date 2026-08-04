import * as Types from '#shared/graphql/types.ts';

import * as Mocks from '#tests/graphql/builders/mocks.ts'
import * as Operations from './customReportGenerate.api.ts'
import * as ErrorTypes from '#shared/types/error.ts'

export function mockCustomReportGenerateMutation(defaults: Mocks.MockDefaultsValue<Types.CustomReportGenerateMutation, Types.CustomReportGenerateMutationVariables>) {
  return Mocks.mockGraphQLResult(Operations.CustomReportGenerateDocument, defaults)
}

export function waitForCustomReportGenerateMutationCalls() {
  return Mocks.waitForGraphQLMockCalls<Types.CustomReportGenerateMutation>(Operations.CustomReportGenerateDocument)
}

export function mockCustomReportGenerateMutationError(message: string, extensions: {type: ErrorTypes.GraphQLErrorTypes }) {
  return Mocks.mockGraphQLResultWithError(Operations.CustomReportGenerateDocument, message, extensions);
}
