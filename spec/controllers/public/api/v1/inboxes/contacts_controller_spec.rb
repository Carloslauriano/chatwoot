require 'rails_helper'

RSpec.describe 'Public Inbox Contacts API', type: :request do
  let!(:api_channel) { create(:channel_api) }
  let!(:contact) { create(:contact, account: api_channel.inbox.account, name: 'Nome Editado Manualmente') }
  let!(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: api_channel.inbox) }

  describe 'PATCH /public/api/v1/inboxes/{identifier}/contacts/{id}' do
    it 'does not overwrite the existing contact name' do
      patch "/public/api/v1/inboxes/#{api_channel.identifier}/contacts/#{contact_inbox.source_id}",
            params: { name: 'Nome Antigo Da Integracao', email: 'novo@example.com' }

      expect(response).to have_http_status(:success)
      expect(contact.reload.name).to eq 'Nome Editado Manualmente'
      expect(contact.email).to eq 'novo@example.com'
    end
  end
end
