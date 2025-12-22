# Script de Reindexação de Organizações

Este script reconstrói o índice de busca das organizações, incluindo os campos customizados (CNPJ, CPF, CODCLIENTE, etc.).

## Quando usar

- Após adicionar novos campos customizados do tipo `input` ou `textarea` às organizações
- Após modificar o método `search_index_attribute_lookup` em `Organization::SearchIndex`
- Quando a busca por CNPJ/CPF/CODCLIENTE não está funcionando corretamente

## Métodos de execução

### Opção 1: Rake Task (Recomendado)

```bash
cd source
rails zammad:searchindex:organization:reload
```

Para usar múltiplos workers (mais rápido em sistemas com muitos processadores):

```bash
rails zammad:searchindex:organization:reload[4]
```

### Opção 2: Script Ruby direto

```bash
cd source
rails runner script/reindex_organizations.rb
```

### Opção 3: Console Rails

```bash
cd source
rails console
```

E então execute:

```ruby
Organization.search_index_reload
```

## O que o script faz

1. Verifica se o Elasticsearch está configurado
2. Lista os campos customizados encontrados
3. Reindexa todas as organizações
4. Mostra o tempo gasto na operação

## Campos pesquisáveis

Após a reindexação, você poderá buscar organizações por:

- **Nome** da organização
- **CNPJ** (com ou sem formatação: "12.345.678/0001-90" ou "12345678000190")
- **CPF** (com ou sem formatação: "123.456.789-00" ou "12345678900")
- **CODCLIENTE** (qualquer valor)
- Qualquer outro campo customizado do tipo `input` ou `textarea`

## Notas

- A reindexação pode levar alguns minutos dependendo da quantidade de organizações
- O script não afeta outras entidades (Tickets, Users, etc.)
- Se você precisar reindexar tudo, use: `rails zammad:searchindex:reload`

