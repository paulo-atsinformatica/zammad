# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Organization
  module SearchIndex
    extend ActiveSupport::Concern

    def search_index_attribute_lookup(include_references: true)
      attributes = super

      if include_references

        # add org members for search index data
        attributes['members'] = []
        users = members | secondary_members
        users.sort.each do |user|
          attributes['members'].push user.search_index_attribute_lookup(include_references: false)
        end
      end

      # Ensure custom text fields (CNPJ, CPF, CODCLIENTE, etc.) are searchable
      # Get all custom input/text fields for Organization
      custom_text_fields = ObjectManager::Attribute
        .where(
          object_lookup_id: ObjectLookup.by_name('Organization'),
          data_type:        %w[input textarea],
          active:           true
        )
        .pluck(:name)

      custom_text_fields.each do |field_name|
        next if attributes[field_name].blank?

        field_value = attributes[field_name].to_s
        next if field_value.blank?

        # Add text version for full-text search (ensures it's indexed as text)
        attributes["#{field_name}_text"] = field_value

        # Create cleaned version (remove formatting characters) for better matching
        # This allows searching "12.345.678/0001-90" by typing "12345678000190"
        cleaned_value = field_value.gsub(/[.\-\/\s]/, '')
        attributes["#{field_name}_clean"] = cleaned_value if cleaned_value.present? && cleaned_value != field_value
      end

      attributes
    end
  end
end
