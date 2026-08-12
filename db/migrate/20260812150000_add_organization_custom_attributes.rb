# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Customização ATS: campos customizados de Organização usados no ERP da ATS.

class AddOrganizationCustomAttributes < ActiveRecord::Migration[8.0]
  # Em instalação nova quem cria estes campos é db/seeds/organization_custom_attributes.rb,
  # que não roda de novo aqui. Esta migration existe para as instalações já em
  # produção, onde os seeds não voltam a rodar.
  def up
    return if !Setting.exists?(name: 'system_init_done')

    organization_id = ObjectLookup.by_name('Organization')

    attributes.each do |attribute|
      next if ObjectManager::Attribute.exists?(object_lookup_id: organization_id, name: attribute[:name])

      add_organization_attribute(attribute)
    end

    ObjectManager::Attribute.migration_execute(false)
  end

  def down
    # Nada a desfazer: remover colunas apagaria dados reais de organização.
  end

  private

  def attributes
    [
      { name: 'razaosocial',        display: 'Razão Social',            position: 1801 },
      { name: 'cpf',                display: 'CPF',                     position: 1802 },
      { name: 'cnpj',               display: 'CNPJ',                    position: 1803 },
      { name: 'codcliente',         display: 'CodCliente',              position: 1804 },
      { name: 'perfildeacesso',     display: 'Perfil de acesso',        position: 1805 },
      { name: 'classificacao',      display: 'Classificação',           position: 1806 },
      { name: 'cep',                display: 'CEP',                     position: 1807 },
      { name: 'endereco',           display: 'Endereço',                position: 1808 },
      { name: 'numero',             display: 'Número',                  position: 1809 },
      { name: 'complemento',        display: 'Complemento',             position: 1810 },
      { name: 'bairro',             display: 'Bairro',                  position: 1812 },
      { name: 'cidade',             display: 'Cidade',                  position: 1813 },
      { name: 'estado',             display: 'Estado',                  position: 1814 },
      { name: 'pais',               display: 'Pais',                    position: 1815 },
      { name: 'observacao',         display: 'Observação',              position: 1816, data_type: 'textarea' },
      { name: 'grupoeconomico',     display: 'Grupo Econômico',         position: 1819 },
      { name: 'unidaderesponsavel', display: 'Unidade Responsável',     position: 1820 },
      { name: 'nomegrupoeconomico', display: 'Nome do Grupo Econômico', position: 1822 },
      { name: 'email',              display: 'E-mail',                  position: 1823 },
    ]
  end

  # Nunca chama .add num campo que já existe: um campo customizado é uma
  # coluna real (ver ObjectManager::Attribute.migration_execute), e
  # sobrescrever a configuração de um campo já em uso em produção poderia
  # alterar o que já está lá.
  def add_organization_attribute(attribute)
    data_type = attribute[:data_type] || 'input'

    data_option = if data_type == 'textarea'
                    { type: 'text', maxlength: 500, rows: 4, null: true, item_class: 'formGroup--halfSize' }
                  else
                    { type: 'text', maxlength: 200, null: true, item_class: 'formGroup--halfSize' }
                  end

    ObjectManager::Attribute.add(
      object:        'Organization',
      name:          attribute[:name],
      display:       attribute[:display],
      data_type:     data_type,
      data_option:   data_option,
      editable:      true,
      internal:      false,
      active:        true,
      screens:       {
        edit:   { '-all-' => { null: true } },
        create: { '-all-' => { null: true } },
        view:   { '-all-' => { shown: true } },
      },
      position:      attribute[:position],
      created_by_id: 1,
      updated_by_id: 1,
    )
  end
end
