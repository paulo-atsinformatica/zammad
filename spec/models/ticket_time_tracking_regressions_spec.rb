# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/
# Customização ATS: controle de tempo de atendimento.

require 'rails_helper'

# Cenários que já quebraram em produção. Cada bloco cita o sintoma, para uma
# falha aqui dizer o que voltou a acontecer para o usuário.
RSpec.describe TicketTimeTracking, :aggregate_failures, type: :model do
  let(:group)      { create(:group) }
  let(:user)       { create(:agent, groups: [group]) }
  let(:other_user) { create(:agent, groups: [group]) }
  let(:ticket)     { create(:ticket, group: group, owner: user) }

  def tracking_for(owner = user, ticket_record = ticket, **attributes)
    create(:ticket_time_tracking,
           ticket:        ticket_record,
           user:          owner,
           created_by_id: owner.id,
           updated_by_id: owner.id,
           **attributes)
  end

  # Sintoma: o agente pausava o ticket A, ia para o B e recebia mesmo assim
  # "Você já está atendendo o ticket #A".
  describe 'pausing frees the user slot' do
    it 'takes the tracking out of the active scope' do
      tracking = tracking_for
      tracking.pause!

      expect(tracking.reload.is_active).to be(false)
      expect(user.reload.active_ticket_tracking).to be_nil
    end

    it 'keeps it resumable' do
      tracking = tracking_for
      tracking.pause!

      expect(described_class.resumable).to include(tracking)
      expect(user.reload.resumable_ticket_tracking).to eq(tracking)
    end

    it 'lets the user start a tracking on another ticket' do
      tracking_for.pause!

      other_ticket = create(:ticket, group: group, owner: user)
      result = TicketTimeTrackingService.new(current_user: user, ticket: other_ticket).start_tracking

      expect(result.success?).to be(true)
    end
  end

  # Sintoma: uma contagem pausada ficava em limbo — não havia como encerrá-la.
  describe 'ending a paused tracking' do
    it 'closes it' do
      tracking = tracking_for
      tracking.pause!

      expect(tracking.end!).to be_truthy
      expect(tracking.reload.ended_at).to be_present
    end

    it 'refuses to end twice' do
      tracking = tracking_for
      tracking.end!

      expect(tracking.end!).to be(false)
    end
  end

  # Sintoma: ao trocar de ticket, um intervalo JÁ ENCERRADO era reativado e
  # voltava a correr, porque a busca não filtrava ended_at.
  describe 'resumable scope' do
    it 'excludes an ended tracking' do
      tracking = tracking_for
      tracking.pause!
      tracking.end!

      expect(described_class.resumable).not_to include(tracking)
    end
  end

  # Sintoma: o cronômetro voltava a 00:00:00 depois de o ticket ir para outro
  # dono e retornar, apesar do tempo já trabalhado.
  describe '#ticket_total_seconds' do
    it 'sums the previous passes of the same user on the ticket' do
      tracking_for(user, ticket, is_active: false, ended_at: Time.zone.now, total_seconds: 120)
      current = tracking_for(user, ticket, total_seconds: 30)

      expect(current.ticket_total_seconds).to eq(150)
    end

    it 'ignores the time of other agents' do
      tracking_for(other_user, ticket, is_active: false, ended_at: Time.zone.now, total_seconds: 999)
      current = tracking_for(user, ticket, total_seconds: 30)

      expect(current.ticket_total_seconds).to eq(30)
    end
  end

  # Sintoma: transferir ou remover o proprietário deixava a contagem do dono
  # anterior correndo. O gancho existia mas nunca disparava.
  describe 'owner change' do
    it 'ends the tracking of the previous owner on transfer' do
      tracking = tracking_for

      ticket.update!(owner: other_user)

      expect(tracking.reload.ended_at).to be_present
    end

    it 'ends it when the owner is removed' do
      tracking = tracking_for

      ticket.update!(owner_id: 1)

      expect(tracking.reload.ended_at).to be_present
    end

    it 'clears the sidebar indicator of the previous owner' do
      user.update!(current_active_ticket_id: ticket.id)
      tracking_for

      ticket.update!(owner: other_user)

      expect(user.reload.current_active_ticket_id).to be_nil
    end

    it 'leaves the tracking of another ticket alone' do
      other_ticket = create(:ticket, group: group, owner: other_user)
      untouched = tracking_for(other_user, other_ticket)

      ticket.update!(owner: other_user)

      expect(untouched.reload.ended_at).to be_nil
    end
  end

  # Sintoma: contagem esquecida corria por noites e fins de semana, e o tempo
  # entrava no relatório.
  describe '.close_stale' do
    it 'closes a tracking running for longer than the limit' do
      stale = tracking_for(user, ticket, started_at: 20.hours.ago)

      described_class.close_stale

      expect(stale.reload.ended_at).to be_present
    end

    it 'leaves a recent one running' do
      recent = tracking_for(user, ticket, started_at: 1.hour.ago)

      described_class.close_stale

      expect(recent.reload.ended_at).to be_nil
    end

    # Uma contagem retomada agora não pode morrer por ter começado há dias.
    it 'measures the current segment, not the original start' do
      resumed = tracking_for(user, ticket, started_at: 5.days.ago, resumed_at: 10.minutes.ago)

      described_class.close_stale

      expect(resumed.reload.ended_at).to be_nil
    end

    it 'is disabled when the limit is zero' do
      Setting.set('ticket_time_tracking_max_running_hours', 0)
      stale = tracking_for(user, ticket, started_at: 20.hours.ago)

      expect(described_class.close_stale).to eq(0)
      expect(stale.reload.ended_at).to be_nil
    end
  end

  # Sintoma potencial: o estado do player ia por broadcast para toda sessão
  # autenticada, cliente inclusive, revelando qual agente está em qual ticket.
  describe 'broadcast recipients' do
    it 'does not include a customer without access to the group' do
      customer = create(:customer)
      tracking = tracking_for

      expect(tracking.send(:recipient_ids)).not_to include(customer.id)
    end

    it 'includes agents who may read the ticket group' do
      tracking = tracking_for

      expect(tracking.send(:recipient_ids)).to include(other_user.id)
    end
  end
end
