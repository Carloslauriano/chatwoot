# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ticket do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:conversation) }
    it { is_expected.to belong_to(:contact) }
    it { is_expected.to belong_to(:responsavel) }
    it { is_expected.to belong_to(:team).optional(true) }
    it { is_expected.to belong_to(:ticket_status).optional(true) }
  end

  describe '#tempo_liquido_segundos' do
    let(:ticket) { create(:ticket) }

    it 'is zero when there are no worklogs' do
      expect(ticket.tempo_liquido_segundos).to eq(0)
    end

    it 'sums all worklogs regardless of status' do
      create(:worklog, ticket: ticket, account: ticket.account, duracao_segundos: 1800)
      create(:worklog, ticket: ticket, account: ticket.account, duracao_segundos: 900)

      expect(ticket.tempo_liquido_segundos).to eq(2700)
    end
  end

  describe '#tempo_bruto_segundos' do
    it 'uses the conversation created_at as the raw time origin' do
      travel_to(Time.zone.parse('2026-08-18 12:00:00')) do
        ticket = create(:ticket)
        ticket.conversation.update_column(:created_at, Time.zone.parse('2026-08-18 10:00:00'))

        expect(ticket.reload.tempo_bruto_segundos).to eq(2.hours.to_i)
      end
    end
  end

  describe '#status_macro' do
    it 'sets resolvido_em when moved to resolvido' do
      ticket = create(:ticket, status_macro: :fazendo)

      ticket.update!(status_macro: :resolvido)

      expect(ticket.resolvido_em).to be_present
    end

    it 'clears resolvido_em when moved away from resolvido' do
      ticket = create(:ticket, status_macro: :resolvido)

      ticket.update!(status_macro: :fazendo)

      expect(ticket.resolvido_em).to be_nil
    end
  end
end
