# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TicketAuditLog do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:ticket) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:acao) }
    it { is_expected.to validate_presence_of(:autor_id) }
  end
end
