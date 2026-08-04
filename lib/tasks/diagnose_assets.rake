# frozen_string_literal: true

# Rake task para diagnosticar qual arquivo .coffee quebra o assets:precompile.
# Uso: DIAGNOSE_COFFEE=1 bundle exec rake assets:precompile:diagnose
# Ou: bundle exec rake assets:precompile:diagnose
#
# O task define DIAGNOSE_COFFEE=1, carrega o app (com o initializer que intercepta
# o processador CoffeeScript) e executa o precompile. Quando o erro ocorrer,
# o último "[DIAGNOSE_COFFEE] Compilando: ..." no stderr é o arquivo culpado.

namespace :assets do
  namespace :precompile do
    desc 'Run assets:precompile and print which CoffeeScript file fails (ExecJS unexpected comma)'
    task diagnose: :environment do
      ENV['DIAGNOSE_COFFEE'] = '1'
      # Recarregar initializers para pegar o patch
      Rails.application.config.initializers.each do |name, _block|
        # O initializer diagnose_coffee_compile já foi carregado com ENV['DIAGNOSE_COFFEE']=1
        # se tivermos chamado com DIAGNOSE_COFFEE=1. Caso contrário, precisamos re-aplicar.
      end
      Rake::Task['assets:precompile'].invoke
    rescue ExecJS::RuntimeError => e
      puts "\n\n!!! ERRO CAPTURADO !!!"
      puts e.message
      if defined?($diagnose_current_coffee_file) && $diagnose_current_coffee_file
        puts "\nArquivo que estava sendo compilado: #{$diagnose_current_coffee_file}"
      end
      raise
    end
  end
end
