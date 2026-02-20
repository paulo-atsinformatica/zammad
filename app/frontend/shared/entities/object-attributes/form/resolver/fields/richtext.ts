<<<<<<< HEAD
// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import type { FieldResolverModule } from '#shared/entities/object-attributes/types/resolver.ts'

import { FieldResolver } from '../FieldResolver.ts'

export class FieldResolverRichtext extends FieldResolver {
  fieldType = 'editor'

  // TODO:
  // def field_for_oa_type_richtext(context:, attribute:)
  //   FormSchema::Field::Editor.new(
  //     **base_attributes(context: context, attribute: attribute),
  //     // TODO: the OA has a maxlength attribute, but Field::Editor does not support that yet.
  //     // maxlength: attribute[:data_option]['maxlength']
  //   )
  // end
  public fieldTypeAttributes() {
    return {
      props: {
        extensionSet: 'basic',
      },
    }
  }
}

export default <FieldResolverModule>{
  type: 'richtext',
  resolver: FieldResolverRichtext,
}
=======
// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import type { FieldResolverModule } from '#shared/entities/object-attributes/types/resolver.ts'

import { FieldResolver } from '../FieldResolver.ts'

export class FieldResolverRichtext extends FieldResolver {
  fieldType = 'editor'

  public fieldTypeAttributes() {
    return {
      props: {
        extensionSet: 'basic',
        // Pass maxlength from dataOption to meta.footer for character count display limit
        meta: {
          footer: {
            maxlength: this.attributeConfig.maxlength ? +this.attributeConfig.maxlength : undefined,
          },
        },
      },
    }
  }
}

export default <FieldResolverModule>{
  type: 'richtext',
  resolver: FieldResolverRichtext,
}
>>>>>>> upstream/develop
