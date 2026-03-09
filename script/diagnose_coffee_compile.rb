#!/usr/bin/env ruby
# frozen_string_literal: true

# Diagnóstico: descobre qual arquivo .coffee gera JavaScript com "unexpected ," na compilação.
# Uso: bundle exec ruby script/diagnose_coffee_compile.rb
# Ou no Docker: RUN bundle exec ruby script/diagnose_coffee_compile.rb

require 'pathname'
require 'bundler/setup'
require 'coffee_script'
require 'execjs'

ASSETS_ROOT = Pathname(__dir__).join('../app/assets/javascripts')
COFFEE_FILES = ASSETS_ROOT.join('**/*.coffee').to_s

puts "Procurando arquivos .coffee em #{ASSETS_ROOT}..."
paths = Pathname.glob(COFFEE_FILES).sort
puts "Encontrados #{paths.size} arquivos."
puts ""

# 1) Encontrar arquivos que compilam para >= 497 linhas (candidatos)
candidates = []
paths.each_with_index do |path, i|
  rel = path.relative_path_from(Pathname(__dir__).join('..'))
  print "\rCompilando #{i + 1}/#{paths.size}..." if (i % 20).zero?
  source = File.read(path)
  js = CoffeeScript.compile(source, filename: path.to_s)
  candidates << [path, js] if js.lines.size >= 497
rescue => e
  puts "\nErro ao compilar #{rel}: #{e.message}"
end

puts "\n\nArquivos que compilam para >= 497 linhas: #{candidates.size}"

# 2) Para cada candidato, avaliar o JS e ver se dá "unexpected ," em 497:88
candidates.each do |path, js|
  rel = path.relative_path_from(Pathname(__dir__).join('..'))
  ExecJS.eval(js)
rescue ExecJS::RuntimeError => e
  if e.message.include?('497') && e.message.include?('unexpected')
    puts "\n" + "=" * 80
    puts "ARQUIVO QUE FALHA: #{rel}"
    puts "=" * 80
    puts "Erro: #{e.message}"
    lines = js.lines
    puts "\nContexto no JS compilado (linhas 492-502, coluna 88):"
    lines[491, 12].each_with_index do |line, idx|
      num = 492 + idx
      mark = (num == 497 && line.length >= 88) ? "  <<< col 88 = '#{line[87]}'" : ""
      puts "#{num}: #{line.chomp}#{mark}"
    end
    exit 1
  end
end

puts "\nNenhum candidato reproduziu o erro ao avaliar."
puts "Verificando vírgula na linha 497 col 88 dos candidatos..."
candidates.each do |path, js|
  lines = js.lines
  next if lines.size < 497
  line497 = lines[496]
  next if line497.nil? || line497.length < 88
  c = line497[87]
  if c == ','
    rel = path.relative_path_from(Pathname(__dir__).join('..'))
    puts "\n#{rel} tem vírgula na linha 497 col 88 do JS compilado:"
    puts lines[491, 12].map.with_index(492) { |l, n| "#{n}: #{l.chomp}" }.join("")
  end
end
puts "\nFim do diagnóstico."
