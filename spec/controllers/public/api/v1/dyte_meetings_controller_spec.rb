require 'rails_helper'

RSpec.describe 'Public Dyte Meetings API', type: :request do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }

  describe 'GET public/api/v1/dyte_meetings/{conversation_uuid}/{meeting_id}/join' do
    it 'renders a page embedding the RealtimeKit meeting URL in an iframe' do
      allow_any_instance_of(Integrations::Dyte::ProcessorService) # rubocop:disable RSpec/AnyInstance
        .to receive(:add_participant_to_meeting).with('meeting_id', conversation.contact).and_return({ 'token' => 'participant_token' })

      get "/public/api/v1/dyte_meetings/#{conversation.uuid}/meeting_id/join"

      expect(response).to have_http_status(:success)
      expect(response.body).to include(
        'https://examples.realtime.cloudflare.com/meeting/?authToken=participant_token&amp;disableVideoBackground=true&amp;showSetupScreen=true'
      )
    end

    it 'returns an error response when the meeting cannot be joined' do
      allow_any_instance_of(Integrations::Dyte::ProcessorService) # rubocop:disable RSpec/AnyInstance
        .to receive(:add_participant_to_meeting).and_return({ error: 'boom' })

      get "/public/api/v1/dyte_meetings/#{conversation.uuid}/meeting_id/join"

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'returns not found for an unknown conversation' do
      get "/public/api/v1/dyte_meetings/#{SecureRandom.uuid}/meeting_id/join"

      expect(response).to have_http_status(:not_found)
    end
  end
end
