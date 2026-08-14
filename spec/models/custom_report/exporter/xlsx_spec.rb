# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: relatório personalizado.

require 'rails_helper'

RSpec.describe CustomReport::Exporter::Xlsx do
  subject(:exporter) do
    described_class.new(run: run, query: query, columns: columns, summary: nil)
  end

  let(:group) { create(:group) }
  let(:user)  { create(:agent, groups: [group]) }

  # Nenhum exemplo referencia o ticket, mas ele precisa existir: é o que a query
  # devolve, e sem linha alguma a planilha sairia só com o cabeçalho.
  let!(:ticket) { create(:ticket, group: group, title: 'chamado de teste') } # rubocop:disable RSpec/LetSetup

  let(:report) do
    create(:custom_report, object: 'Ticket', condition: {}, columns: %w[number title])
  end

  # filename é preenchido por CustomReportRun.enqueue!, não pela factory, e
  # prepare_file_path! precisa dele.
  let(:run) do
    create(:custom_report_run,
           custom_report: report,
           format:        'xlsx',
           filename:      CustomReportRun.suggested_filename(report, 'xlsx'))
  end

  let(:query)   { CustomReport::Query.new(report: report, user: user) }
  let(:columns) { CustomReport::Columns.new(report: report, user: user) }

  after do
    FileUtils.rm_rf(CustomReportRun.storage_path.join(run.id.to_s))
  end

  # Esta geração quebrou em produção com "undefined method 'set_constant_memory'
  # for an instance of Writexlsx::Format": o construtor do WriteXLSX trata como
  # propriedade de formato toda chave fora da própria allowlist, então uma opção
  # inexistente vira `set_<chave>` no Format em vez de erro de argumento. Sem um
  # teste que gere o arquivo de verdade, nada disso aparece.
  it 'writes a spreadsheet' do
    result = exporter.call

    expect(result[:rows]).to eq(1)
  end

  it 'produces a non-empty file on disk' do
    result = exporter.call

    expect(File.size(result[:path])).to be_positive
  end

  # xlsx é um zip; os primeiros bytes denunciam um arquivo que não abriria.
  it 'produces a file Excel can open' do
    result = exporter.call

    expect(File.binread(result[:path], 2)).to eq('PK')
  end

  it 'reports the size it wrote' do
    result = exporter.call

    expect(result[:filesize]).to eq(File.size(result[:path]))
  end
end
