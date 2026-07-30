// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
// Customização ATS: relatório personalizado.

// Filtros preenchidos por quem visualiza, no formato de selector do Zammad.
// A chave é o nome do atributo; o backend só aplica os que o relatório habilitou
// e só com operador permitido para o tipo do atributo
// (ver CustomReport::Query#allowed_runtime_filters e
// CustomReport::FilterDefinition::OPERATORS_BY_TYPE).
export interface RuntimeFilter {
  operator: string
  value: string | string[]
}

export type RuntimeFilters = Record<string, RuntimeFilter>

export interface AvailableFilterOption {
  value: string
  label: string
}

// O tipo decide o controle renderizado. Quem determina é o backend, a partir da
// coluna e da relação do atributo.
export type AvailableFilterType = 'select' | 'date' | 'boolean' | 'text'

export interface AvailableFilter {
  name: string
  display: string
  type: AvailableFilterType
  options: AvailableFilterOption[]
}
