// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
// Customização ATS: relatório personalizado.

// Filtros preenchidos por quem visualiza, no formato de selector do Zammad.
// A chave é o nome do atributo; o backend só aplica os que o relatório habilitou
// (ver CustomReport::Query#allowed_runtime_filters).
export interface RuntimeFilter {
  operator: string
  value: string
}

export type RuntimeFilters = Record<string, RuntimeFilter>

export interface AvailableFilter {
  name: string
  display: string
}
