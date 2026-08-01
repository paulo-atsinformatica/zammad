import * as Types from '#shared/graphql/types.ts';

import gql from 'graphql-tag';
import * as VueApolloComposable from '@vue/apollo-composable';
import * as VueCompositionApi from 'vue';
export type ReactiveFunction<TParam> = () => TParam;

export const CustomReportListDocument = gql`
    query customReportList($scope: String) {
  customReportList(scope: $scope) {
    id
    name
    object
    active
  }
}
    `;
export function useCustomReportListQuery(variables: Types.CustomReportListQueryVariables | VueCompositionApi.Ref<Types.CustomReportListQueryVariables> | ReactiveFunction<Types.CustomReportListQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.CustomReportListQuery, Types.CustomReportListQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.CustomReportListQuery, Types.CustomReportListQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.CustomReportListQuery, Types.CustomReportListQueryVariables>> = {}) {
  return VueApolloComposable.useQuery<Types.CustomReportListQuery, Types.CustomReportListQueryVariables>(CustomReportListDocument, variables, options);
}
export function useCustomReportListLazyQuery(variables: Types.CustomReportListQueryVariables | VueCompositionApi.Ref<Types.CustomReportListQueryVariables> | ReactiveFunction<Types.CustomReportListQueryVariables> = {}, options: VueApolloComposable.UseQueryOptions<Types.CustomReportListQuery, Types.CustomReportListQueryVariables> | VueCompositionApi.Ref<VueApolloComposable.UseQueryOptions<Types.CustomReportListQuery, Types.CustomReportListQueryVariables>> | ReactiveFunction<VueApolloComposable.UseQueryOptions<Types.CustomReportListQuery, Types.CustomReportListQueryVariables>> = {}) {
  return VueApolloComposable.useLazyQuery<Types.CustomReportListQuery, Types.CustomReportListQueryVariables>(CustomReportListDocument, variables, options);
}
export type CustomReportListQueryCompositionFunctionResult = VueApolloComposable.UseQueryReturn<Types.CustomReportListQuery, Types.CustomReportListQueryVariables>;