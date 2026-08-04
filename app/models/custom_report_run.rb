# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: uma geração (execução) de relatório personalizado.

class CustomReportRun < ApplicationModel
  include HasDefaultModelUserRelations

  FORMATS  = %w[csv xlsx].freeze
  STATUSES = %w[pending running succeeded failed].freeze

  # Tempo que o arquivo gerado fica disponível para download. Relatórios podem
  # ser grandes, então sem expiração o disco enche com o tempo.
  RETENTION = 7.days

  belongs_to :custom_report

  validates :format, presence: true, inclusion: { in: FORMATS }
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :recent, -> { reorder(created_at: :desc) }
  scope :for_user, ->(user) { where(created_by_id: user.id) }
  scope :expired, -> { where(expires_at: ..Time.zone.now) }

  after_destroy :remove_file

  # Ponto único de enfileiramento, usado pela API REST e pelo GraphQL, para as
  # duas rotas concordarem sobre formato padrão e nome de arquivo.
  #
  # Enfileira em vez de gerar na hora: relatórios grandes estourariam o tempo da
  # requisição e prenderiam um worker web.
  def self.enqueue!(report:, format: nil)
    format = FORMATS.include?(format.to_s) ? format.to_s : 'csv'

    run = create!(
      custom_report: report,
      format:        format,
      status:        'pending',
      filename:      suggested_filename(report, format),
    )

    CustomReportGenerateJob.perform_later(run: run)

    run
  end

  def self.suggested_filename(report, format)
    slug = report.name.to_s.parameterize.presence || 'report'

    "#{slug}-#{Time.zone.now.strftime('%Y%m%d-%H%M%S')}.#{format}"
  end

  # Volume compartilhado em Docker (zammad-storage). O job roda no scheduler e
  # o download é servido pelo railsserver, então não pode ser tmp local.
  def self.storage_path
    Rails.root.join('storage/custom_report_runs')
  end

  # Chamado pelo Scheduler. Sem isso os arquivos gerados acumulam no volume
  # até encher o disco.
  def self.cleanup
    expired.find_each(&:destroy!)

    # Diretórios órfãos (ex. registro removido direto no banco) também somem,
    # senão o espaço nunca é recuperado.
    return if !storage_path.exist?

    existing_ids = pluck(:id).map(&:to_s)
    storage_path.children.each do |dir|
      next if !dir.directory?
      next if existing_ids.include?(dir.basename.to_s)

      FileUtils.rm_rf(dir)
    end
  end

  def finished?
    %w[succeeded failed].include?(status)
  end

  def downloadable?
    status == 'succeeded' && !expired? && file_path&.exist?
  end

  def file_path
    return if filename.blank?

    self.class.storage_path.join(id.to_s, filename)
  end

  def prepare_file_path!
    path = self.class.storage_path.join(id.to_s)
    FileUtils.mkdir_p(path)
    path.join(filename)
  end

  def expired?
    expires_at.present? && expires_at <= Time.zone.now
  end

  # Percentual só existe depois da contagem inicial; antes disso a UI mostra
  # apenas "processando".
  def progress_percent
    return if total_rows.blank? || total_rows.zero?

    [(processed_rows.to_f / total_rows * 100).round, 100].min
  end

  private

  def remove_file
    FileUtils.rm_rf(self.class.storage_path.join(id.to_s))
  rescue => e
    Rails.logger.error "Could not remove generated file of CustomReportRun #{id}: #{e.message}"
  end
end
