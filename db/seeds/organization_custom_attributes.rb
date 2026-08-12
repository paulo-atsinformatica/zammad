# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: campos customizados de Organização usados no ERP da ATS.

# Estes campos já existem em produção (criados manualmente pela tela de
# Gerenciar > Objetos), mas nunca foram capturados no código — uma instalação
# nova, ou este ambiente de teste, fica sem eles. Separado de
# db/seeds/object_manager_attributes.rb de propósito: aquele arquivo é 100%
# stock do Zammad (campos internos, "internal: true"), e misturar customização
# nele aumentaria o risco de conflito num sync com o upstream.
#
# Só cria o que ainda não existe — nunca chama .add em um campo já presente.
# Um campo customizado vira coluna real da tabela (ver
# ActiveRecord::Migration.add_column em ObjectManager::Attribute.migration_execute),
# então sobrescrever a configuração de um campo que já existe em produção
# poderia alterar (ou apagar) opções reais já em uso — especialmente arriscado
# nos campos do tipo select/multiselect.
#
# Pendente: 'segmento' (select), 'modulos' (multiselect) e 'codrota' (select)
# ficam de fora até termos a lista real de opções configuradas em produção —
# inventar valores aqui poderia divergir do que já está em uso.
ORGANIZATION_CUSTOM_ATTRIBUTES = [
  { name: 'razaosocial',        display: __('Razão Social'),            position: 1801 },
  { name: 'cpf',                display: __('CPF'),                     position: 1802 },
  { name: 'cnpj', display: __('CNPJ'), position: 1803 },
  { name: 'codcliente',         display: __('CodCliente'),              position: 1804 },
  { name: 'perfildeacesso',     display: __('Perfil de acesso'),        position: 1805 },
  { name: 'classificacao',      display: __('Classificação'),           position: 1806 },
  { name: 'cep',                display: __('CEP'),                     position: 1807 },
  { name: 'endereco',           display: __('Endereço'),                position: 1808 },
  { name: 'numero',             display: __('Número'),                  position: 1809 },
  { name: 'complemento',        display: __('Complemento'),             position: 1810 },
  { name: 'bairro',             display: __('Bairro'),                  position: 1812 },
  { name: 'cidade',             display: __('Cidade'),                  position: 1813 },
  { name: 'estado',             display: __('Estado'),                  position: 1814 },
  { name: 'pais',               display: __('Pais'),                    position: 1815 },
  { name: 'observacao',         display: __('Observação'),              position: 1816, data_type: 'textarea' },
  { name: 'grupoeconomico',     display: __('Grupo Econômico'),         position: 1819 },
  { name: 'unidaderesponsavel', display: __('Unidade Responsável'),     position: 1820 },
  { name: 'nomegrupoeconomico', display: __('Nome do Grupo Econômico'), position: 1822 },
  { name: 'email',              display: __('E-mail'),                  position: 1823 },
].freeze

def organization_custom_attribute_data_option(attribute)
  return { type: 'text', maxlength: 500, rows: 4, null: true, item_class: 'formGroup--halfSize' } if attribute[:data_type] == 'textarea'

  { type: 'text', maxlength: 200, null: true, item_class: 'formGroup--halfSize' }
end

ORGANIZATION_CUSTOM_ATTRIBUTES.each do |attribute|
  next if ObjectManager::Attribute.exists?(
    object_lookup_id: ObjectLookup.by_name('Organization'),
    name:             attribute[:name],
  )

  ObjectManager::Attribute.add(
    object:        'Organization',
    name:          attribute[:name],
    display:       attribute[:display],
    data_type:     attribute[:data_type] || 'input',
    data_option:   organization_custom_attribute_data_option(attribute),
    editable:      true,
    internal:      false,
    active:        true,
    screens:       {
      edit:   { '-all-' => { null: true } },
      create: { '-all-' => { null: true } },
      view:   { '-all-' => { shown: true } },
    },
    position:      attribute[:position],
    # Sem usuário atual no contexto de um seed/migration isolado — validação de
    # created_by/updated_by exige que sejam explícitos aqui.
    created_by_id: 1,
    updated_by_id: 1,
  )
end

ObjectManager::Attribute.migration_execute(false)
