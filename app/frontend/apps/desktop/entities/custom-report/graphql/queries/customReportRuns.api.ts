import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const CustomReportRunsDocument = gql`
    query customReportRuns($limit: Int) {
  customReportRuns(limit: $limit) {
    id
    format
    status
    filename
    totalRows
    processedRows
    progressPercent
    errorMessage
    createdAt
    downloadable
    downloadPath
    customReport {
      id
      name
    }
  }
}
    `;
export function useCustomReportRunsQuery(variables: Types.CustomReportRunsQueryVariables | VueCompositionApi.Ref<Types.CustomReportRunsQueryVariables> | ReactiveFunction<Types.CustomReportRunsQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.CustomReportRunsQuery, Types.CustomReportRunsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.CustomReportRunsQuery, Types.CustomReportRunsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.CustomReportRunsQuery, Types.CustomReportRunsQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.CustomReportRunsQuery, Types.CustomReportRunsQueryVariables>(CustomReportRunsDocument, variables, options);
}
export function useCustomReportRunsLazyQuery(variables: Types.CustomReportRunsQueryVariables | VueCompositionApi.Ref<Types.CustomReportRunsQueryVariables> | ReactiveFunction<Types.CustomReportRunsQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.CustomReportRunsQuery, Types.CustomReportRunsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.CustomReportRunsQuery, Types.CustomReportRunsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.CustomReportRunsQuery, Types.CustomReportRunsQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.CustomReportRunsQuery, Types.CustomReportRunsQueryVariables>(CustomReportRunsDocument, variables, options);
}
export type CustomReportRunsQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.CustomReportRunsQuery, Types.CustomReportRunsQueryVariables>;