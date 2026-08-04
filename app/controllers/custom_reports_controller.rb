# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: relatório personalizado.

class CustomReportsController < ApplicationController
  prepend_before_action :authentication_check
  before_action :check_permission
  before_action :check_admin_permission, only: %i[search]
  before_action :set_report, only: %i[show update destroy generate results]
  before_action :set_run, only: %i[run_show download]

  # GET /api/v1/custom_reports?scope=all|group|personal
  def index
    reports = filter_by_scope(CustomReport.visible_to(current_user))

    render json: {
      custom_reports: reports.reorder(name: :asc).map { |report| report_json(report) },
      objects:        CustomReport::OBJECTS,
    }, status: :ok
  end

  # GET|POST /api/v1/custom_reports/search
  #
  # Alimenta o grid paginado de Gerenciar > Relatórios Personalizados. Devolve
  # todos os modelos, inclusive inativos e de outros usuários, por isso é
  # restrito a admin.custom_report — quem só tem report.custom usa #index, que
  # aplica a visibilidade.
  def search
    model_search_render(CustomReport, params)
  end

  def show
    render json: report_json(@report), status: :ok
  end

  def create
    report = CustomReport.new(report_params)

    report.save!
    render json: report_json(report), status: :created
  end

  def update
    return render_not_editable if !@report.editable_by?(current_user)

    @report.update!(report_params)
    render json: report_json(@report), status: :ok
  end

  def destroy
    return render_not_editable if !@report.editable_by?(current_user)

    @report.destroy!
    render json: {}, status: :ok
  end

  # GET /api/v1/custom_reports/:id/results
  #
  # Página de resultados para o grid. Distinto de #generate: aqui nada é
  # enfileirado nem escrito em disco, é só uma leitura paginada — por isso
  # responde na hora, sem passar pela fila.
  def results
    result = CustomReport::Result.new(
      report:          @report,
      user:            current_user,
      filters:         runtime_filters,
      page:            params[:page],
      per_page:        params[:per_page],
      order_by:        params[:order_by],
      order_direction: params[:order_direction],
    ).call

    render json: result, status: :ok
  end

  # POST /api/v1/custom_reports/:id/generate
  def generate
    run = CustomReportRun.enqueue!(report: @report, format: params[:format])

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
              filename:    @run.filename,
              type:        content_type_for(@run.format),
              disposition: 'attachment'
  end

  private

  # Lista com OR: quem administra os modelos não precisa ter report.custom para
  # gerenciá-los. O recorte dos dados continua sendo feito em
  # CustomReport::Query, com as permissões de quem pede.
  def check_permission
    return if current_user.permissions?(%w[report.custom admin.custom_report])

    render json: { error: __('You do not have permission to use custom reports.') }, status: :forbidden
  end

  def check_admin_permission
    return if current_user.permissions?('admin.custom_report')

    render json: { error: __('You do not have permission to manage custom reports.') }, status: :forbidden
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
    params.permit(:name, :object, :active,
                  group_ids: [], user_ids: [], columns: [], group_by: [], aggregations: [],
                  aggregation_attributes: [], enabled_filters: [], condition: {})
  end

  # Filtros preenchidos por quem visualiza. O que pode ou não ser filtrado é
  # decidido em CustomReport::Query, contra os filtros habilitados no modelo.
  def runtime_filters
    return if params[:filters].blank?

    params.require(:filters).permit!.to_h
  end

  # Recorte da lista, sempre dentro do que o usuário já enxerga.
  def filter_by_scope(reports)
    case params[:scope]
    when 'group'    then reports.joins(:groups).where(groups: { id: CustomReport.visible_group_ids(current_user) })
    when 'personal' then reports.where(created_by_id: current_user.id)
    else reports
    end
  end

  def render_not_editable
    render json: { error: __('Only the author of a report can change it.') }, status: :forbidden
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
