# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: relatório personalizado.

# Levantada quando o resultado não cabe no formato pedido. Existe como classe
# própria para o job distinguir um limite de formato de uma falha inesperada.
class CustomReport::Exporter::TooManyRowsError < StandardError
end
