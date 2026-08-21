# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActiveTimer do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:ticket) }
    it { is_expected.to belong_to(:colaborador) }
  end

  describe 'RN01 — timer único por colaborador' do
    it 'does not allow two active timers for the same colaborador, even on different tickets' do
      account = create(:account)
      colaborador = create(:user, account: account)
      ticket_a = create(:ticket, account: account)
      ticket_b = create(:ticket, account: account)
      create(:active_timer, account: account, ticket: ticket_a, colaborador: colaborador)

      segundo_timer = build(:active_timer, account: account, ticket: ticket_b, colaborador: colaborador)

      expect(segundo_timer).not_to be_valid
      expect { segundo_timer.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
