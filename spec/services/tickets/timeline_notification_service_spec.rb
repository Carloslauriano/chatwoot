require 'rails_helper'

describe Tickets::TimelineNotificationService do
  let(:account) { create(:account) }
  let(:responsavel) { create(:user, account: account) }
  let(:colaborador) { create(:user, account: account) }
  let(:ticket) { create(:ticket, account: account, responsavel: responsavel) }

  before do
    create(:ticket_assignment, account: account, ticket: ticket, colaborador: colaborador)
  end

  context 'when the event has an actor' do
    let(:event) do
      create(:ticket_timeline_event, account: account, ticket: ticket, tipo_evento: :comentario, autor_id: colaborador.id,
                                     payload: { texto: 'oi' })
    end

    it 'notifies the responsavel' do
      expect(responsavel.notifications.where(notification_type: 'ticket_activity', account: account,
                                             primary_actor: ticket, secondary_actor: event)).to exist
    end

    it 'does not notify the actor who caused the event' do
      expect(colaborador.notifications.where(notification_type: 'ticket_activity', account: account,
                                             primary_actor: ticket, secondary_actor: event)).not_to exist
    end
  end

  context 'when the event has no actor (system-generated)' do
    let(:event) { create(:ticket_timeline_event, account: account, ticket: ticket, tipo_evento: :status_macro_changed) }

    it 'notifies every recipient' do
      expect(responsavel.notifications.where(notification_type: 'ticket_activity', primary_actor: ticket,
                                             secondary_actor: event)).to exist
      expect(colaborador.notifications.where(notification_type: 'ticket_activity', primary_actor: ticket,
                                             secondary_actor: event)).to exist
    end
  end

  context 'when the responsavel is also the actor and there are no other recipients' do
    let(:solo_ticket) { create(:ticket, account: account, responsavel: responsavel) }
    let(:event) { create(:ticket_timeline_event, account: account, ticket: solo_ticket, tipo_evento: :comentario, autor_id: responsavel.id) }

    it 'does not create any notification' do
      expect(event.ticket.notifications).to be_empty
    end
  end

  context 'when the same recipient would be notified twice for the same event' do
    let(:event) do
      create(:ticket_timeline_event, account: account, ticket: ticket, tipo_evento: :comentario, autor_id: colaborador.id)
    end

    it 'does not duplicate the notification' do
      expect do
        described_class.new(ticket_timeline_event: event).perform
      end.not_to(change { responsavel.notifications.count })
    end
  end
end
