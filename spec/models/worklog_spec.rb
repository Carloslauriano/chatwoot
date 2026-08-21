# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Worklog do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:ticket) }
    it { is_expected.to belong_to(:colaborador) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:inicio) }
    it { is_expected.to validate_presence_of(:fim) }
    it { is_expected.to validate_presence_of(:duracao_segundos) }
  end
end
