# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TicketTimelineListener do
  let(:listener) { described_class.instance }
  let(:ticket) { create(:ticket) }

  describe '#conversation_status_changed' do
    it 'creates a status_macro_changed timeline event for the linked ticket' do
      event = Events::Base.new('conversation.status_changed', Time.zone.now, conversation: ticket.conversation, performed_by: nil)

      expect { listener.conversation_status_changed(event) }.to change(ticket.ticket_timeline_events, :count).by(1)
    end

    it 'marks the ticket as resolvido when the linked conversation is resolved' do
      ticket.conversation.update!(status: :resolved)
      event = Events::Base.new('conversation.status_changed', Time.zone.now, conversation: ticket.conversation, performed_by: nil)

      expect { listener.conversation_status_changed(event) }.to change { ticket.reload.status_macro }.from('caixa_entrada').to('resolvido')
    end

    it 'moves the ticket back to caixa_entrada when the linked conversation is reopened' do
      ticket.update!(status_macro: :resolvido)
      ticket.conversation.update!(status: :open)
      event = Events::Base.new('conversation.status_changed', Time.zone.now, conversation: ticket.conversation, performed_by: nil)

      expect { listener.conversation_status_changed(event) }.to change { ticket.reload.status_macro }.from('resolvido').to('caixa_entrada')
    end
  end
end
