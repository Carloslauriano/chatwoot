# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TicketTimelineListener do
  let(:listener) { described_class.instance }
  let(:ticket) { create(:ticket) }

  describe '#message_created' do
    it 'creates a timeline event when the message belongs to a ticketed conversation' do
      message = create(:message, conversation: ticket.conversation, account: ticket.account, message_type: :incoming)
      event = Events::Base.new('message.created', Time.zone.now, message: message, performed_by: nil)

      expect { listener.message_created(event) }.to change(ticket.ticket_timeline_events, :count).by(1)
      expect(ticket.ticket_timeline_events.last.tipo_evento).to eq('mensagem_cliente')
    end

    it 'does nothing when the conversation has no linked ticket' do
      message = create(:message, message_type: :incoming)
      event = Events::Base.new('message.created', Time.zone.now, message: message, performed_by: nil)

      expect { listener.message_created(event) }.not_to change(TicketTimelineEvent, :count)
    end
  end

  describe '#conversation_status_changed' do
    it 'creates a status_macro_changed timeline event for the linked ticket' do
      event = Events::Base.new('conversation.status_changed', Time.zone.now, conversation: ticket.conversation, performed_by: nil)

      expect { listener.conversation_status_changed(event) }.to change(ticket.ticket_timeline_events, :count).by(1)
    end
  end
end
