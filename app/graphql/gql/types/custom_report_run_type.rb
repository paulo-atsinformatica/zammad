# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: relatório personalizado.

module Gql::Types
  class CustomReportRunType < Gql::Types::BaseObject
    description 'One generation (export) of a custom report'

    # Mesmo motivo de CustomReportType: o resto da API resolve objetos por ID
    # global, então este tipo não pode expor o id cru.
    global_id_field :id

    field :custom_report, Gql::Types::CustomReportType, null: false, description: 'Report this run belongs to'
    field :format, String, null: false, description: 'csv or xlsx'
    field :status, String, null: false, description: 'pending, running, succeeded or failed'
    field :filename, String

    field :total_rows, Integer, description: 'Rows to process, known only after the initial count'
    field :processed_rows, Integer
    field :progress_percent, Integer, description: 'Nil until the total row count is known'

    field :error_message, String, description: 'Reason the generation failed'
    field :expires_at, GraphQL::Types::ISO8601DateTime, description: 'When the generated file is removed'
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false

    field :downloadable, Boolean, null: false, description: 'Whether the file can be downloaded right now', method: :downloadable?

    # O download é um GET autenticado por cookie de sessão, servido fora do
    # GraphQL por send_file (arquivos podem ser grandes). Aqui só entregamos o
    # caminho, relativo ao api_path, para a tela montar o link com
    # <CommonLink rest-api>.
    field :download_path, String, description: 'Path relative to api_path to download the file, nil while unavailable'

    def download_path
      return if !object.downloadable?

      "/custom_report_runs/#{object.id}/download"
    end
  end
end
