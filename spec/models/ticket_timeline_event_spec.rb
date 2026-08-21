# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TicketTimelineEvent do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:ticket) }
  end

  it 'exposes the expected tipo_evento values' do
    expect(described_class.tipo_evento.keys).to contain_exactly(
      'mensagem_cliente', 'nota_interna', 'status_macro_changed',
      'status_micro_changed', 'setor_changed', 'worklog', 'worklog_manual'
    )
  end
end
