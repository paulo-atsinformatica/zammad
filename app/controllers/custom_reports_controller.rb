# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: relatório personalizado.

class CustomReportsController < ApplicationController
  prepend_before_action :authentication_check
  before_action :check_permission
  before_action :set_report, only: %i[show update destroy generate]
  before_action :set_run, only: %i[run_show download]

  # GET /api/v1/custom_reports?visibility=all|global|group|personal
  def index
    reports = CustomReport.visible_to(current_user)
    reports = filter_by_visibility(reports)

    render json: {
      custom_reports: reports.reorder(name: :asc).map { |report| report_json(report) },
      objects:        CustomReport::OBJECTS,
      can_share:      shareable_visibilities,
    }, status: :ok
  end

  def show
    render json: report_json(@report), status: :ok
  end

  def create
    report = CustomReport.new(report_params)
    authorize_visibility!(report.visibility)

    report.save!
    render json: report_json(report), status: :created
  end

  def update
    return render_not_editable if !@report.editable_by?(current_user)

    authorize_visibility!(report_params[:visibility]) if report_params.key?(:visibility)

    @report.update!(report_params)
    render json: report_json(@report), status: :ok
  end

  def destroy
    return render_not_editable if !@report.editable_by?(current_user)

    @report.destroy!
    render json: {}, status: :ok
  end

  # POST /api/v1/custom_reports/:id/generate
  #
  # Enfileira a geração em vez de responder com o arquivo: relatórios grandes
  # estourariam o tempo da requisição e prenderiam um worker web.
  def generate
    run = CustomReportRun.create!(
      custom_report: @report,
      format:        params[:format].presence || 'csv',
      status:        'pending',
      filename:      suggested_filename(@report, params[:format]),
    )

    CustomReportGenerateJob.perform_later(run: run)

    render json: run_json(run), status: :accepted
  end

  # GET /api/v1/custom_report_runs
  def runs
    runs = CustomReportRun.for_user(current_user).recent.limit(50)

    render json: { custom_report_runs: runs.map { |run| run_json(run) } }, status: :ok
  end

  # GET /api/v1/custom_report_runs/:id — usado para acompanhar o progresso
  # quando o WebSocket não estiver disponível.
  def run_show
    render json: run_json(@run), status: :ok
  end

  # GET /api/v1/custom_report_runs/:id/download
  #
  # send_file transmite direto do disco, sem carregar o arquivo em memória.
  def download
    if !@run.downloadable?
      return render json: { error: __('This report is not available for download.') }, status: :not_found
    end

    send_file @run.file_path,
              filename: @run.filename,
              type:     content_type_for(@run.format),
              disposition: 'attachment'
  end

  private

  def check_permission
    return if current_user.permissions?('report.custom')

    render json: { error: __('You do not have permission to use custom reports.') }, status: :forbidden
  end

  def set_report
    @report = CustomReport.find(params[:id])

    return if @report.visible_to?(current_user)

    # Não revela a existência de um relatório que o usuário não enxerga.
    raise ActiveRecord::RecordNotFound
  end

  # Uma execução pertence a quem a disparou: o arquivo já contém dados
  # materializados sob as permissões daquele usuário, então não pode ser
  # baixado por outro, mesmo que ambos vejam o mesmo modelo.
  def set_run
    @run = CustomReportRun.for_user(current_user).find(params[:id])
  end

  def report_params
    params.permit(:name, :object, :visibility, :active, group_ids: [], columns: [], group_by: [], aggregations: [], condition: {})
  end

  def filter_by_visibility(reports)
    case params[:visibility]
    when 'global'   then reports.where(visibility: 'global')
    when 'group'    then reports.where(visibility: 'group')
    when 'personal' then reports.where(visibility: 'personal', created_by_id: current_user.id)
    else reports
    end
  end

  def shareable_visibilities
    %w[personal] + CustomReport::VISIBILITY_PERMISSIONS.select do |_visibility, permission|
      current_user.permissions?(permission)
    end.keys
  end

  def authorize_visibility!(visibility)
    permission = CustomReport::VISIBILITY_PERMISSIONS[visibility.to_s]
    return if permission.blank?
    return if current_user.permissions?(permission)

    raise Exceptions::Forbidden, __('You do not have permission to share reports at this level.')
  end

  def render_not_editable
    render json: { error: __('Only the author of a report can change it.') }, status: :forbidden
  end

  def suggested_filename(report, format)
    slug = report.name.to_s.parameterize.presence || 'report'
    ext  = format.to_s == 'xlsx' ? 'xlsx' : 'csv'

    "#{slug}-#{Time.zone.now.strftime('%Y%m%d-%H%M%S')}.#{ext}"
  end

  def content_type_for(format)
    format == 'xlsx' ? ExcelSheet::CONTENT_TYPE : 'text/csv'
  end

  def report_json(report)
    report.attributes_with_association_ids.merge(
      'editable' => report.editable_by?(current_user),
    )
  end

  def run_json(run)
    run.attributes_with_association_ids.merge(
      'progress_percent' => run.progress_percent,
      'downloadable'     => run.downloadable?,
    )
  end
end
