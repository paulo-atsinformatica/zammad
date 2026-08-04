// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
// Customização ATS: relatório personalizado.

import { mockGraphQLResult } from '#tests/graphql/builders/mocks.ts'
import { visitView } from '#tests/support/components/visitView.ts'
import { mockPermissions } from '#tests/support/mock-permissions.ts'

import type {
  CustomReportListQuery,
  CustomReportListQueryVariables,
  CustomReportResultsQuery,
  CustomReportResultsQueryVariables,
} from '#shared/graphql/types.ts'

import { CustomReportListDocument } from '../../../entities/custom-report/graphql/queries/customReportList.api.ts'
import { CustomReportResultsDocument } from '../../../entities/custom-report/graphql/queries/customReportResults.api.ts'

// Os ids vêm codificados do backend (Gql::ZammadSchema), mas para o mock só
// importa que sejam distintos entre si.
const FIRST_REPORT = { id: 'gid://zammad/CustomReport/1', name: 'Tickets abertos' }
const SECOND_REPORT = { id: 'gid://zammad/CustomReport/2', name: 'Tickets fechados' }

const mockReports = () =>
  mockGraphQLResult<CustomReportListQuery, CustomReportListQueryVariables>(
    CustomReportListDocument,
    {
      customReportList: [
        { ...FIRST_REPORT, object: 'Ticket', active: true },
        { ...SECOND_REPORT, object: 'Ticket', active: true },
      ],
    },
  )

// Cada relatório devolve uma coluna própria, para o teste distinguir qual dos
// dois está na tela.
//
// Os dois usam o MESMO id de linha de propósito: o id de uma linha é o id do
// registro de origem, então dois relatórios sobre Ticket que alcancem o mesmo
// ticket produzem linhas de id igual. É exatamente esse o caso que quebrava —
// com ids distintos o problema não aparece.
const SHARED_ROW_ID = '1'

const mockResults = () =>
  mockGraphQLResult<CustomReportResultsQuery, CustomReportResultsQueryVariables>(
    CustomReportResultsDocument,
    (variables) => {
      const isSecond = variables.customReportId === SECOND_REPORT.id
      const column = isSecond ? 'closed_at' : 'title'
      const value = isSecond ? 'fechado em janeiro' : 'chamado de teste'

      return {
        customReportResults: {
          columns: [{ name: column, display: column }],
          enabledFilters: [],
          rows: [{ id: SHARED_ROW_ID, values: { [column]: value } }],
          summary: null,
          totalCount: 1,
          page: 1,
          perPage: 50,
          totalPages: 1,
        },
      }
    },
  )

describe('custom report screen', () => {
  beforeEach(() => {
    mockPermissions(['report.custom'])
    mockReports()
    mockResults()
  })

  it('keeps rendering the grid after switching between reports', async () => {
    const view = await visitView('/custom-reports')

    // Abre no primeiro relatório da lista, sem o usuário escolher nada.
    expect(await view.findByText('chamado de teste')).toBeInTheDocument()

    await view.events.click(await view.findByRole('button', { name: SECOND_REPORT.name }))

    // A regressão relatada: ao trocar de relatório o grid sumia e não voltava.
    expect(await view.findByText('fechado em janeiro')).toBeInTheDocument()

    await view.events.click(await view.findByRole('button', { name: FIRST_REPORT.name }))

    // E voltar ao anterior também não trazia o grid de volta.
    expect(await view.findByText('chamado de teste')).toBeInTheDocument()
  })
})
