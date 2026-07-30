import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const CustomReportResultsDocument = gql`
    query customReportResults($customReportId: ID!, $filters: JSON, $page: Int, $perPage: Int, $orderBy: String, $orderDirection: String) {
  customReportResults(
    customReportId: $customReportId
    filters: $filters
    page: $page
    perPage: $perPage
    orderBy: $orderBy
    orderDirection: $orderDirection
  ) {
    columns {
      name
      display
    }
    enabledFilters {
      name
      display
      type
      options {
        value
        label
      }
    }
    rows {
      id
      values
    }
    totalCount
    page
    perPage
    totalPages
  }
}
    `;
export function useCustomReportResultsQuery(variables: Types.CustomReportResultsQueryVariables | VueCompositionApi.Ref<Types.CustomReportResultsQueryVariables> | ReactiveFunction<Types.CustomReportResultsQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.CustomReportResultsQuery, Types.CustomReportResultsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.CustomReportResultsQuery, Types.CustomReportResultsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.CustomReportResultsQuery, Types.CustomReportResultsQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.CustomReportResultsQuery, Types.CustomReportResultsQueryVariables>(CustomReportResultsDocument, variables, options);
}
export function useCustomReportResultsLazyQuery(variables?: Types.CustomReportResultsQueryVariables | VueCompositionApi.Ref<Types.CustomReportResultsQueryVariables> | ReactiveFunction<Types.CustomReportResultsQueryVariables>, options: VueApolloComposable.UseQueryOptions<Types.CustomReportResultsQuery, Types.CustomReportResultsQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.CustomReportResultsQuery, Types.CustomReportResultsQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.CustomReportResultsQuery, Types.CustomReportResultsQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.CustomReportResultsQuery, Types.CustomReportResultsQueryVariables>(CustomReportResultsDocument, variables, options);
}
export type CustomReportResultsQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.CustomReportResultsQuery, Types.CustomReportResultsQueryVariables>;