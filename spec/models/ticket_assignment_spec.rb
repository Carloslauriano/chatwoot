# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TicketAssignment do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:ticket) }
    it { is_expected.to belong_to(:colaborador) }
  end

  describe 'validations' do
    it 'does not allow the same colaborador to be assigned twice to the same ticket' do
      ticket = create(:ticket)
      colaborador = create(:user, account: ticket.account)
      create(:ticket_assignment, ticket: ticket, account: ticket.account, colaborador: colaborador)

      duplicated = build(:ticket_assignment, ticket: ticket, account: ticket.account, colaborador: colaborador)

      expect(duplicated).not_to be_valid
    end
  end
end
