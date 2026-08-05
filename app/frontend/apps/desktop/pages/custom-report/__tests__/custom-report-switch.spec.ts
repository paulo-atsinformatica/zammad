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

  // O id do relatório muda no clique, mas os filtros só chegam com a resposta.
  // Remontando o formulário pelo id, ele nascia com os filtros do relatório
  // anterior e a atualização de props seguinte não os removia — Form.vue mescla
  // campos por nome —, então a tela ficava sempre um passo atrás.
  it('shows the filters of the report that is selected, on every switch', async () => {
    mockGraphQLResult<CustomReportResultsQuery, CustomReportResultsQueryVariables>(
      CustomReportResultsDocument,
      (variables) => {
        const isSecond = variables.customReportId === SECOND_REPORT.id

        return {
          customReportResults: {
            columns: [{ name: 'title', display: 'Título' }],
            enabledFilters: isSecond
              ? [{ name: 'closed_at', display: 'Fechado em', type: 'date', options: [] }]
              : [{ name: 'title', display: 'Título do chamado', type: 'text', options: [] }],
            rows: [{ id: '3', values: { title: 'chamado' } }],
            summary: null,
            totalCount: 1,
            page: 1,
            perPage: 50,
            totalPages: 1,
          },
        }
      },
    )

    const view = await visitView('/custom-reports')

    expect(await view.findByLabelText('Título do chamado')).toBeInTheDocument()

    await view.events.click(await view.findByRole('button', { name: SECOND_REPORT.name }))

    expect(await view.findByLabelText('Fechado em')).toBeInTheDocument()
    expect(view.queryByLabelText('Título do chamado')).not.toBeInTheDocument()

    // A volta é onde aparecia o atraso.
    await view.events.click(await view.findByRole('button', { name: FIRST_REPORT.name }))

    expect(await view.findByLabelText('Título do chamado')).toBeInTheDocument()
    expect(view.queryByLabelText('Fechado em')).not.toBeInTheDocument()
  })

  // Espelha o payload real: quatro colunas nos dois relatórios, dois nomes em
  // comum, e as mesmas linhas — porque os dois relatórios correm sobre Ticket e
  // alcançam os mesmos tickets. O contador de colunas igual desarma o reset de
  // larguras de CommonTable, então este caso exercita um caminho que o anterior
  // não alcança.
  it('keeps rendering when both reports have the same column count', async () => {
    mockGraphQLResult<CustomReportResultsQuery, CustomReportResultsQueryVariables>(
      CustomReportResultsDocument,
      (variables) => {
        const isSecond = variables.customReportId === SECOND_REPORT.id

        const columns = isSecond
          ? ['title', 'customer_id', 'closed_at', 'group_id']
          : ['title', 'customer_id', 'owner_id', 'state_id']

        const cell = (column: string) => (isSecond ? `B ${column}` : `A ${column}`)

        return {
          customReportResults: {
            columns: columns.map((name) => ({ name, display: name })),
            enabledFilters: [],
            rows: ['3', '4', '5'].map((id) => ({
              id,
              values: Object.fromEntries(columns.map((name) => [name, `${cell(name)} ${id}`])),
            })),
            summary: null,
            totalCount: 3,
            page: 1,
            perPage: 50,
            totalPages: 1,
          },
        }
      },
    )

    const view = await visitView('/custom-reports')

    expect(await view.findByText('A owner_id 3')).toBeInTheDocument()

    await view.events.click(await view.findByRole('button', { name: SECOND_REPORT.name }))

    expect(await view.findByText('B closed_at 3')).toBeInTheDocument()

    await view.events.click(await view.findByRole('button', { name: FIRST_REPORT.name }))

    expect(await view.findByText('A owner_id 3')).toBeInTheDocument()
  })

  // Um relatório com totalizadores mas sem agrupamento devolve summary com
  // groupBy e rows vazios e só o total geral preenchido. O bloco do resultado
  // desenha o resumo e a tabela juntos, então um resumo que quebre leva a tabela
  // junto — e os filtros, que ficam fora do bloco, continuariam na tela.
  it('renders the grid for a report whose summary has no grouping', async () => {
    mockGraphQLResult<CustomReportResultsQuery, CustomReportResultsQueryVariables>(
      CustomReportResultsDocument,
      {
        customReportResults: {
          columns: [
            { name: 'number', display: '#' },
            { name: 'title', display: 'Título' },
          ],
          enabledFilters: [],
          rows: [{ id: '3', values: { number: '43003', title: 'chamado de teste' } }],
          summary: {
            groupBy: [],
            aggregations: [{ name: 'count', display: 'Contagem' }],
            rows: [],
            totals: { count: 3 },
          },
          totalCount: 3,
          page: 1,
          perPage: 50,
          totalPages: 1,
        },
      },
    )

    const view = await visitView('/custom-reports')

    expect(await view.findByText('chamado de teste')).toBeInTheDocument()
  })

  // Payload copiado de uma instância real: relatório sem colunas escolhidas, que
  // cai no conjunto padrão e devolve 25 delas. É a única dimensão em que esse
  // relatório difere do que funciona.
  const WIDE_COLUMNS = [
    'number',
    'title',
    'customer_id',
    'organization_id',
    'group_id',
    'owner_id',
    'state_id',
    'pending_time',
    'priority_id',
    'article_count',
    'time_unit',
    'escalation_at',
    'first_response_escalation_at',
    'update_escalation_at',
    'close_escalation_at',
    'last_contact_at',
    'last_contact_agent_at',
    'last_contact_customer_at',
    'first_response_at',
    'close_at',
    'last_close_at',
    'created_by_id',
    'created_at',
    'updated_by_id',
    'updated_at',
  ]

  it('renders a report that falls back to the full default column set', async () => {
    mockGraphQLResult<CustomReportResultsQuery, CustomReportResultsQueryVariables>(
      CustomReportResultsDocument,
      {
        customReportResults: {
          columns: WIDE_COLUMNS.map((name) => ({ name, display: name })),
          enabledFilters: [],
          // Metade dos valores vem nula na instância real (escalonamento, datas
          // de contato), então o teste mantém esse formato.
          rows: [
            {
              id: '3',
              values: Object.fromEntries(
                WIDE_COLUMNS.map((name, index) => [
                  name,
                  name === 'title' ? 'chamado de teste' : index % 2 === 0 ? null : `v${index}`,
                ]),
              ),
            },
          ],
          summary: {
            groupBy: [],
            aggregations: [{ name: 'count', display: 'Contagem' }],
            rows: [],
            totals: { count: 3 },
          },
          totalCount: 3,
          page: 1,
          perPage: 50,
          totalPages: 1,
        },
      },
    )

    const view = await visitView('/custom-reports')

    expect(await view.findByText('chamado de teste')).toBeInTheDocument()
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
