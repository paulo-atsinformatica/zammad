# frozen_string_literal: true

# Só carrega quando DIAGNOSE_COFFEE=1 para identificar qual .coffee quebra o assets:precompile.
# Uso: DIAGNOSE_COFFEE=1 bundle exec rake assets:precompile
# O arquivo que está sendo compilado quando o erro ocorre será o último impresso em "Compilando: ...".

return unless ENV['DIAGNOSE_COFFEE'] == '1'

processor = nil
begin
  require 'sprockets/coffee_script_processor'
  processor = Sprockets::CoffeeScriptProcessor
rescue LoadError
  processor = nil
end
processor = Sprockets::CoffeeScriptProcessor if processor.nil? && defined?(Sprockets::CoffeeScriptProcessor)

if processor
  module DiagnoseCoffeeCompile
    def call(input)
      filename = input[:filename] || input[:name] || input[:load_path]
      $diagnose_current_coffee_file = filename
      $stderr.puts "[DIAGNOSE_COFFEE] Compilando: #{filename}"
      super(input)
    end
  end
  processor.prepend(DiagnoseCoffeeCompile)
end
