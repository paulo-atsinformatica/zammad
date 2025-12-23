#!/usr/bin/env ruby
# frozen_string_literal: true

# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/
#
# Script para reconstruir o índice de busca das organizações
# Útil após adicionar campos customizados (CNPJ, CPF, CODCLIENTE, etc.)
#
# Uso:
#   rails runner script/reindex_organizations.rb
#   ou
#   ruby script/reindex_organizations.rb (se executado do diretório source)

require_relative '../config/environment'

puts '=' * 60
puts 'Reindexando Organizações'
puts '=' * 60
puts ''

# Verificar se o search index está configurado
unless SearchIndexBackend.configured?
  puts 'ERRO: Elasticsearch não está configurado.'
  puts 'Configure o Elasticsearch antes de executar este script.'
  exit 1
end

# Verificar se o search index está habilitado
unless SearchIndexBackend.enabled?
  puts 'AVISO: Search Index Backend não está habilitado.'
  puts 'As organizações não serão indexadas.'
  exit 0
end

puts "Total de organizações: #{Organization.count}"
puts ''

# Contar organizações com campos customizados
custom_fields = ObjectManager::Attribute
  .where(
    object_lookup_id: ObjectLookup.by_name('Organization'),
    data_type:        %w[input textarea],
    active:           true,
    editable:         true
  )
  .pluck(:name)

if custom_fields.any?
  puts "Campos customizados encontrados: #{custom_fields.join(', ')}"
  puts 'Esses campos serão incluídos na busca.'
else
  puts 'Nenhum campo customizado do tipo input/textarea encontrado.'
end

puts ''
puts 'Iniciando reindexação...'
puts ''

start_time = Time.now

begin
  # Reindexar todas as organizações
  Organization.search_index_reload(silent: false)

  elapsed_time = Time.now - start_time

  puts ''
  puts '=' * 60
  puts "Reindexação concluída com sucesso em #{elapsed_time.to_i} segundos!"
  puts '=' * 60
  puts ''
  puts 'Agora você pode buscar organizações por:'
  puts '  - Nome'
  if custom_fields.include?('cnpj')
    puts '  - CNPJ (com ou sem formatação)'
  end
  if custom_fields.include?('cpf')
    puts '  - CPF (com ou sem formatação)'
  end
  if custom_fields.include?('codcliente')
    puts '  - CODCLIENTE'
  end
  puts ''

rescue => e
  puts ''
  puts '=' * 60
  puts 'ERRO durante a reindexação:'
  puts e.message
  puts e.backtrace.first(5).join("\n")
  puts '=' * 60
  exit 1
end



