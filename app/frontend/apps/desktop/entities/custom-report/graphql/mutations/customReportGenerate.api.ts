import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const CustomReportGenerateDocument = gql`
    mutation customReportGenerate($customReportId: ID!, $format: String) {
  customReportGenerate(customReportId: $customReportId, format: $format) {
    customReportRun {
      id
      format
      status
      filename
      createdAt
      downloadable
      downloadPath
    }
    errors {
      message
      field
    }
  }
}
    `;
export function useCustomReportGenerateMutation(options: VueApolloComposable.UseMutationOptions<Types.CustomReportGenerateMutation, Types.CustomReportGenerateMutationVariables> | ReactiveFunction<VueApolloComposable.UseMutationOptions<Types.CustomReportGenerateMutation, Types.CustomReportGenerateMutationVariables>> = {}) {
  return VueApolloComposable.useMutation<Types.CustomReportGenerateMutation, Types.CustomReportGenerateMutationVariables>(CustomReportGenerateDocument, options);
}
export type CustomReportGenerateMutationCompositionFunctionResult = VueApolloComposable.UseMutationReturn<Types.CustomReportGenerateMutation, Types.CustomReportGenerateMutationVariables>;