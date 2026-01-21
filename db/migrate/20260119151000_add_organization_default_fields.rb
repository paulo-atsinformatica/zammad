# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class AddOrganizationDefaultFields < ActiveRecord::Migration[7.2]
  def up
    return if !Setting.exists?(name: 'system_init_done')

    UserInfo.current_user_id = 1

    add_org_field(name: 'razaosocial', display: 'Razão Social', data_type: 'input', position: 1801)
    add_org_field(name: 'cpf', display: 'CPF', data_type: 'input', position: 1802)
    add_org_field(name: 'cnpj', display: 'CNPJ', data_type: 'input', position: 1803)
    add_org_field(name: 'codcliente', display: 'CodCliente', data_type: 'input', position: 1804)
    add_org_field(name: 'perfildeacesso', display: 'Perfil de acesso', data_type: 'input', position: 1805)
    add_org_field(name: 'classificacao', display: 'Classificação', data_type: 'input', position: 1806)
    add_org_field(name: 'cep', display: 'CEP', data_type: 'input', position: 1807)
    add_org_field(name: 'endereco', display: 'Endereço', data_type: 'input', position: 1808)
    add_org_field(name: 'numero', display: 'Número', data_type: 'input', position: 1809)
    add_org_field(name: 'complemento', display: 'Complemento', data_type: 'input', position: 1810)
    add_org_field(name: 'bairro', display: 'Bairro', data_type: 'input', position: 1812)
    add_org_field(name: 'cidade', display: 'Cidade', data_type: 'input', position: 1813)
    add_org_field(name: 'estado', display: 'Estado', data_type: 'input', position: 1814)
    add_org_field(name: 'pais', display: 'Pais', data_type: 'input', position: 1815)

    add_org_field(
      name:        'observacao',
      display:     'Observação',
      data_type:   'textarea',
      data_option: {
        type:      'text',
        maxlength: 10_000,
        null:      true,
        rows:      7,
      },
      position:    1816
    )

    add_org_field(
      name:        'segmento',
      display:     'Segmento',
      data_type:   'select',
      data_option: {
        default:    nil,
        options:    [],
        nulloption: true,
        multiple:   false,
        null:       true,
        translate:  false,
      },
      position:    1817
    )

    add_org_field(
      name:        'modulos',
      display:     'Modulos',
      data_type:   'multiselect',
      data_option: {
        default:    [],
        options:    [],
        nulloption: true,
        multiple:   true,
        null:       true,
        translate:  false,
      },
      position:    1818
    )

    add_org_field(name: 'grupoeconomico', display: 'Grupo Econômico', data_type: 'input', position: 1819)
  end

  def down
    UserInfo.current_user_id = 1

    %w[
      razaosocial cpf cnpj codcliente perfildeacesso classificacao cep endereco numero complemento bairro cidade estado pais
      observacao segmento modulos grupoeconomico
    ].each do |name|
      ObjectManager::Attribute.remove(object: 'Organization', name: name, force: true)
    end
  end

  private

  def add_org_field(name:, display:, data_type:, position:, data_option: nil)
    base_option = {
      type:      'text',
      maxlength: 255,
      null:      true,
    }

    ObjectManager::Attribute.add(
      force:         true,
      object:        'Organization',
      name:          name,
      display:       display,
      data_type:     data_type,
      data_option:   data_option || base_option,
      editable:      false,
      active:        true,
      screens:       {
        create: { '-all-' => { null: true } },
        edit:   { '-all-' => { null: true } },
        view:   { '-all-' => { shown: true } },
      },
      to_create:     false,
      to_migrate:    false,
      to_delete:     false,
      position:      position,
      created_by_id: 1,
      updated_by_id: 1,
    )
  end
end
