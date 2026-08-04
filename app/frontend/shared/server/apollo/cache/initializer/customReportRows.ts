// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
// Customização ATS: relatório personalizado.

import type { InMemoryCacheConfig } from '@apollo/client/cache/inmemory/types'

// Uma linha de relatório não é uma entidade: é a projeção de um registro nas
// colunas daquele relatório. O `id` que ela carrega é o do registro de origem
// (para o grid poder linkar), e não identifica a linha globalmente.
//
// Sem isto o Apollo normaliza por `__typename` + `id`, então dois relatórios
// sobre o mesmo objeto que alcancem o mesmo registro colidem na mesma entrada
// de cache e o `values` de um sobrescreve o do outro. O efeito era o grid ficar
// vazio ao trocar de relatório e não voltar nem retornando ao anterior, porque
// as colunas passavam a procurar chaves que o `values` sobrescrito não tem. Só
// recarregar a página resolvia, por descartar o cache em memória.
//
// `keyFields: false` guarda a linha embutida no resultado que a trouxe, que é
// o único escopo onde ela faz sentido. Mesmo tratamento para a linha de
// totalizadores, pela mesma razão.
export default function register(config: InMemoryCacheConfig) {
  config.typePolicies ||= {}
  config.typePolicies.CustomReportRow = { keyFields: false }
  config.typePolicies.CustomReportSummaryRow = { keyFields: false }

  return config
}
