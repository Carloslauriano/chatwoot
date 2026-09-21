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
      'status_micro_changed', 'setor_changed', 'worklog', 'worklog_manual',
      'membro_added', 'membro_removed', 'comentario'
    )
  end

  describe '#anexos' do
    let(:imagem) { Rack::Test::UploadedFile.new('spec/assets/avatar.png', 'image/png') }

    it 'accepts an attached image when tipo_evento is comentario' do
      event = create(:ticket_timeline_event, tipo_evento: :comentario, payload: { texto: 'oi' })
      event.anexos.attach(imagem)

      expect(event).to be_valid
    end

    it 'rejects an attachment when tipo_evento is not comentario' do
      event = create(:ticket_timeline_event, tipo_evento: :nota_interna)
      event.anexos.attach(imagem)

      expect(event).to be_invalid
      expect(event.errors[:anexos]).to be_present
    end
  end
end
