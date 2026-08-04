// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
// Customização ATS: relatório personalizado.

import type { RouteRecordRaw } from 'vue-router'

// Rota principal, e não filha de LayoutPage: a tela é uma guia independente,
// aberta a partir do menu de Relatórios do SPA legado, e não deve mostrar a
// navegação lateral da Desktop View.
export const isMainRoute = true

// Servida em /report/..., não /desktop/... — ver config/routes/custom_report_ui.rb
// e a base do history em ../../router/index.ts.
const route: RouteRecordRaw[] = [
  {
    // Antes de /custom-reports para o roteador não tentar casar a outra rota
    // primeiro.
    path: '/custom-reports/exports',
    name: 'CustomReportExports',
    component: () => import('./views/CustomReportExports.vue'),
    meta: {
      title: __('Export queue'),
      requiresAuth: true,
      requiredPermission: ['report.custom'],
      hasOwnLandmarks: true,
    },
  },
  {
    path: '/custom-reports',
    name: 'CustomReport',
    component: () => import('./views/CustomReport.vue'),
    meta: {
      title: __('Custom Report'),
      requiresAuth: true,
      // Os dados são sempre recortados pelas permissões de quem abre
      // (ver CustomReport::Query), então esta permissão só controla o acesso
      // à tela.
      requiredPermission: ['report.custom'],
      hasOwnLandmarks: true,
    },
  },
]

export default route
