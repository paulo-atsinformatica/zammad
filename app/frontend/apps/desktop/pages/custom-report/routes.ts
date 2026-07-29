// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
// Customização ATS: relatório personalizado.

import type { RouteRecordRaw } from 'vue-router'

const route: RouteRecordRaw[] = [
  {
    path: '/custom-reports/:customReportId?',
    name: 'CustomReport',
    component: () => import('./views/CustomReport.vue'),
    props: true,
    meta: {
      title: __('Custom Report'),
      requiresAuth: true,
      icon: 'table',
      // Os dados são sempre recortados pelas permissões de quem abre
      // (ver CustomReport::Query), então esta permissão só controla o acesso
      // à tela.
      requiredPermission: ['report.custom'],
      level: 2,
      order: 3000,
      pageKey: 'custom-report',
    },
  },
]

export default route
