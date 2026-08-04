// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
// Customização ATS: o bundle da Desktop View também serve páginas fora de
// /desktop.

// Pontos de montagem conhecidos do bundle. Hoje: a própria Desktop View e a tela
// de relatório personalizado, servida em /report (ver
// config/routes/custom_report_ui.rb).
//
// Lista fechada de propósito: a base do roteador vem daqui, e o primeiro
// segmento da URL não pode virar base arbitrária.
export const MOUNT_POINTS = ['desktop', 'report'] as const

export type MountPoint = (typeof MOUNT_POINTS)[number]

export const DEFAULT_MOUNT_POINT: MountPoint = 'desktop'

export const currentMountPoint = (): MountPoint => {
  const [, firstSegment] = window.location.pathname.split('/')

  return (MOUNT_POINTS as readonly string[]).includes(firstSegment)
    ? (firstSegment as MountPoint)
    : DEFAULT_MOUNT_POINT
}

// Páginas montadas fora de /desktop reaproveitam o bundle, mas não são a
// Desktop View: não devem receber o aviso de BETA nem o fluxo de feedback,
// que falam de uma interface que o usuário nem escolheu abrir.
export const isDesktopView = (): boolean => currentMountPoint() === DEFAULT_MOUNT_POINT
