class Public::Api::V1::DyteMeetingsController < PublicController
  DYTE_MEETING_LINK = 'https://examples.realtime.cloudflare.com/meeting/'.freeze

  layout false

  # Renders an HTML page with the meeting in an iframe (same technique as
  # Dyte.vue) instead of redirecting, so the customer's browser stays on
  # our own domain rather than jumping to examples.realtime.cloudflare.com.
  def join
    conversation = Conversation.find_by!(uuid: params[:conversation_uuid])
    response = dyte_processor_service(conversation).add_participant_to_meeting(params[:meeting_id], conversation.contact)

    if response[:error].present?
      render plain: I18n.t('errors.dyte.realtimekit_credentials_required'), status: :unprocessable_entity
      return
    end

    @meeting_url = build_dyte_url(response['token'])
  end

  private

  def dyte_processor_service(conversation)
    Integrations::Dyte::ProcessorService.new(account: conversation.account, conversation: conversation)
  end

  def build_dyte_url(token)
    query = { authToken: token, showSetupScreen: true, disableVideoBackground: true }.to_query
    "#{DYTE_MEETING_LINK}?#{query}"
  end
end
