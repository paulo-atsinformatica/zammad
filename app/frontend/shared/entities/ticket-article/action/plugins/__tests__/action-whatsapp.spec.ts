<<<<<<< HEAD
// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

// import type {
//   TicketArticle,
//   TicketById,
// } from '#shared/entities/ticket/types.ts'
// import { convertToGraphQLId } from '#shared/graphql/utils.ts'
// import { mockUserCurrent } from '#tests/support/mock-account.ts'
// import { mockApplicationConfig } from '#tests/support/mock-applicationConfig.ts'
// import { setupView } from '#tests/support/mock-user.ts'
// import { nextTick } from 'vue'
// import { createArticleTypes } from '../index.ts'
// import {
//   createEligibleTicketArticleReplyData,
//   createTestArticleActions,
// } from './utils.ts'
import { describe } from 'vitest'
// import { setupView } from '#tests/support/mock-user.ts'
// import {
//   createTestArticleActions,
//   createTicket,
//   createTicketArticle,
// } from '#shared/entities/ticket-article/action/plugins/__tests__/utils.ts'

describe('whatsapp ticket', () => {
  describe('infos', () => {
    it.todo('shows a 24 hours warning window', () => {})
    // it.todo('', () => {
    // setupView('agent')
    // const ticket = createTicket()
    // const article = createTicketArticle({
    //   type: {
    //     name: 'whatsapp message',
    //   },
    // })
    // const actions = createTestArticleActions(ticket, article)
    //   })
  })
  describe('reply actions', () => {
    it.todo('should only allow to upload one attachment', () => {})
    it.todo('should not allow user upload more than one attachment', () => {})
    // describe('attachment size', () => {
    //   it.todo.each(['audio', 'application', 'image', 'video', 'sticker'])(
    //     `prompt user that %s is too large in size`,
    //     (type) => {},
    //   )
    // })
  })
})
=======
// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { setupView } from '#tests/support/mock-user.ts'

import { EnumChannelArea, EnumTicketArticleSenderName } from '#shared/graphql/types.ts'

import {
  createTestArticleActions,
  createTestArticleTypes,
  createTicket,
  createTicketArticle,
} from './utils.ts'

const createWhatsappTicket = (defaults?: any) => {
  const now = Date.now()
  return createTicket({
    policy: { update: true, agentReadAccess: true },
    initialChannel: EnumChannelArea.WhatsAppBusiness,
    preferences: {
      whatsapp: {
        timestamp_incoming: (now - 30 * 60 * 1000) / 1000, // 30 minutes ago
      },
    },
    ...defaults,
  })
}

describe('whatsapp article action', () => {
  describe('reply action', () => {
    it('customer message from whatsapp triggers reply action', () => {
      setupView('agent')

      const ticket = createWhatsappTicket()
      const article = createTicketArticle({
        sender: { name: EnumTicketArticleSenderName.Customer },
        type: { name: 'whatsapp message' },
        messageId: '123456789',
      })

      const actions = createTestArticleActions(ticket, article)
      const replyAction = actions.find((a) => a.name === 'whatsapp message')

      expect(replyAction?.label).toBe('Reply')
      expect(replyAction?.icon).toBe('reply')
      expect(replyAction?.alwaysVisible).toBe(true)
    })

    it('agent message does not trigger reply action', () => {
      setupView('agent')

      const ticket = createWhatsappTicket()
      const article = createTicketArticle({
        sender: { name: EnumTicketArticleSenderName.Agent },
        type: { name: 'whatsapp message' },
      })

      const actions = createTestArticleActions(ticket, article)
      const replyAction = actions.find((a) => a.name === 'whatsapp message')

      expect(replyAction).toBeUndefined()
    })

    it('non-whatsapp message type does not trigger reply action', () => {
      setupView('agent')

      const ticket = createWhatsappTicket()
      const article = createTicketArticle({
        sender: { name: EnumTicketArticleSenderName.Customer },
        type: { name: 'sms' },
      })

      const actions = createTestArticleActions(ticket, article)
      const replyAction = actions.find((a) => a.name === 'whatsapp message')

      expect(replyAction).toBeUndefined()
    })
  })

  describe('whatsapp article type', () => {
    it('whatsapp article type is available for agents', () => {
      setupView('agent')

      const ticket = createWhatsappTicket({
        createArticleType: {
          name: 'whatsapp message',
        },
      })
      const types = createTestArticleTypes(ticket)
      const whatsappType = types.find((t) => t.value === 'whatsapp message')

      expect(whatsappType?.label).toBe('WhatsApp')
      expect(whatsappType?.icon).toBe('whatsapp')
    })

    it('whatsapp article type has correct field configuration', () => {
      setupView('agent')

      const ticket = createWhatsappTicket({
        createArticleType: {
          name: 'whatsapp message',
        },
      })
      const types = createTestArticleTypes(ticket)
      const whatsappType = types.find((t) => t.value === 'whatsapp message')

      expect(whatsappType?.fields?.attachments?.multiple).toBe(false)
      expect(whatsappType?.fields?.body?.required).toBe(false)
      expect(whatsappType?.fields?.body?.validation).toContain('require_one:attachments')
    })

    it('whatsapp article type has correct editor meta configuration', () => {
      setupView('agent')

      const ticket = createWhatsappTicket({
        createArticleType: {
          name: 'whatsapp message',
        },
      })
      const types = createTestArticleTypes(ticket)
      const whatsappType = types.find((t) => t.value === 'whatsapp message')

      expect(whatsappType?.editorMeta?.footer?.maxlength).toBe(4096)
      expect(whatsappType?.editorMeta?.footer?.allowExceedMaxLength).toBe(true)
    })

    it('whatsapp article type is not available for non-whatsapp channels', () => {
      setupView('agent')

      const ticket = createTicket({
        policy: { update: true },
        createArticleType: {
          name: 'whatsapp message',
        },
        initialChannel: EnumChannelArea.GoogleAccount,
      })
      const types = createTestArticleTypes(ticket)
      const whatsappType = types.find((t) => t.value === 'whatsapp message')

      expect(whatsappType).toBeUndefined()
    })

    it('whatsapp article type is not available when service window is closed', () => {
      setupView('agent')

      const now = Date.now()
      const ticket = createTicket({
        policy: { update: true },
        createArticleType: {
          name: 'whatsapp message',
        },
        initialChannel: EnumChannelArea.WhatsAppBusiness,
        preferences: {
          whatsapp: {
            timestamp_incoming: (now - 25 * 60 * 60 * 1000) / 1000, // 25 hours ago
          },
        },
      })

      const types = createTestArticleTypes(ticket)
      const whatsappType = types.find((t) => t.value === 'whatsapp message')

      expect(whatsappType).toBeUndefined()
    })
  })
})
>>>>>>> upstream/develop
