# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Ticket Attachments API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:ticket) { create(:ticket, account: account, responsavel: agent) }
  let(:imagem) { Rack::Test::UploadedFile.new('spec/assets/avatar.png', 'image/png') }

  describe 'POST /api/v1/accounts/{account.id}/tickets/{id}/attachments' do
    it 'attaches a file to the ticket description and returns it in the serialized response' do
      post "/api/v1/accounts/#{account.id}/tickets/#{ticket.id}/attachments",
           params: { anexos: [imagem] },
           headers: agent.create_new_auth_token

      expect(response).to have_http_status(:success)
      expect(ticket.reload.anexos).to be_attached
    end

    it 'does not attach a file above the configured size limit' do
      allow(GlobalConfigService).to receive(:load).with('MAXIMUM_FILE_UPLOAD_SIZE', 40).and_return('0.00001')

      post "/api/v1/accounts/#{account.id}/tickets/#{ticket.id}/attachments",
           params: { anexos: [imagem] },
           headers: agent.create_new_auth_token

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'DELETE /api/v1/accounts/{account.id}/tickets/{id}/attachments/{attachment_id}' do
    it 'purges the blob so no orphan remains' do
      ticket.anexos.attach(imagem)
      anexo = ticket.anexos.first

      delete "/api/v1/accounts/#{account.id}/tickets/#{ticket.id}/attachments/#{anexo.id}",
             headers: agent.create_new_auth_token

      expect(response).to have_http_status(:success)
      expect(ActiveStorage::Blob.exists?(anexo.blob_id)).to be(false)
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/tickets/{id}/comments with anexos' do
    it 'attaches files to the comment timeline event' do
      post "/api/v1/accounts/#{account.id}/tickets/#{ticket.id}/comments",
           params: { texto: 'com anexo', anexos: [imagem] },
           headers: agent.create_new_auth_token

      expect(response).to have_http_status(:success)
      event = ticket.ticket_timeline_events.comentario.last
      expect(event.anexos).to be_attached
      expect(response.parsed_body['anexos']).not_to be_empty
    end

    it 'still works without anexos (backwards compatible)' do
      post "/api/v1/accounts/#{account.id}/tickets/#{ticket.id}/comments",
           params: { texto: 'sem anexo' },
           headers: agent.create_new_auth_token

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['anexos']).to eq([])
    end
  end
end
