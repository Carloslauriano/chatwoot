require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::LinkPreviewsController', type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:url) { 'https://example.com/article' }

  before do
    allow(Resolv).to receive(:getaddresses).and_call_original
    allow(Resolv).to receive(:getaddresses).with('example.com').and_return(['93.184.216.34'])
  end

  describe 'POST /api/v1/accounts/:account_id/link_previews' do
    it 'returns the page title when authorized' do
      stub_request(:get, url).to_return(
        status: 200,
        body: '<html><head><title>Article Title</title></head></html>',
        headers: { 'content-type' => 'text/html' }
      )

      post "/api/v1/accounts/#{account.id}/link_previews", headers: user.create_new_auth_token, params: { url: url }

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['title']).to eq('Article Title')
    end

    it 'returns a nil title when the page cannot be fetched, without raising' do
      stub_request(:get, url).to_return(status: 500)

      post "/api/v1/accounts/#{account.id}/link_previews", headers: user.create_new_auth_token, params: { url: url }

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['title']).to be_nil
    end

    it 'is unprocessable when url is missing' do
      post "/api/v1/accounts/#{account.id}/link_previews", headers: user.create_new_auth_token, params: {}

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'is unauthorized without a valid user' do
      post "/api/v1/accounts/#{account.id}/link_previews", headers: {}, params: { url: url }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
