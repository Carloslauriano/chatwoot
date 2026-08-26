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
  end
end
