# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Tickets API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:ticket) { create(:ticket, account: account, responsavel: agent) }

  describe 'POST /api/v1/accounts/{account.id}/tickets/{id}/link_conversation' do
    context 'when the ticket is already resolved (G1)' do
      it 'returns 409 and does not reopen it' do
        ticket.update!(status_macro: :resolvido)
        outra_conversa = create(:conversation, account: account)

        post "/api/v1/accounts/#{account.id}/tickets/#{ticket.id}/link_conversation",
             params: { conversation_id: outra_conversa.id },
             headers: agent.create_new_auth_token,
             as: :json

        expect(response).to have_http_status(:conflict)
        expect(ticket.reload.conversation_id).not_to eq(outra_conversa.id)
      end
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/tickets/{id}/timer/start (RN01)' do
    it 'pauses the timer on ticket A without creating a worklog when Play is pressed on ticket B' do
      ticket_b = create(:ticket, account: account, responsavel: agent)
      create(:active_timer, account: account, ticket: ticket, colaborador: agent)

      post "/api/v1/accounts/#{account.id}/tickets/#{ticket_b.id}/timer/start",
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:success)
      expect(ActiveTimer.where(colaborador_id: agent.id).count).to eq(1)
      expect(ActiveTimer.find_by(colaborador_id: agent.id).ticket_id).to eq(ticket_b.id)
      expect(Worklog.where(ticket: ticket).count).to eq(0)
    end

    it 'does not create two active timers under concurrent requests for the same colaborador' do
      ticket_b = create(:ticket, account: account, responsavel: agent)

      threads = [ticket, ticket_b].map do |t|
        Thread.new do
          post "/api/v1/accounts/#{account.id}/tickets/#{t.id}/timer/start",
               headers: agent.create_new_auth_token,
               as: :json
        end
      end
      threads.each(&:join)

      expect(ActiveTimer.where(colaborador_id: agent.id).count).to eq(1)
    end
  end

  describe 'PATCH /api/v1/accounts/{account.id}/tickets/{id}/transfer (G2)' do
    it 'pauses any active timer tied to the ticket without creating a worklog' do
      create(:active_timer, account: account, ticket: ticket, colaborador: agent)

      patch "/api/v1/accounts/#{account.id}/tickets/#{ticket.id}/transfer",
            params: { setor_destino: 'desenvolvimento' },
            headers: agent.create_new_auth_token,
            as: :json

      expect(response).to have_http_status(:success)
      expect(ticket.reload.setor_atual).to eq('desenvolvimento')
      expect(ActiveTimer.where(ticket: ticket).count).to eq(0)
      expect(Worklog.where(ticket: ticket).count).to eq(0)
    end
  end

  describe 'GET /api/v1/accounts/{account.id}/tickets/{id} — tempo_liquido_segundos (US09)' do
    it 'is zero when there are no worklogs, never an error' do
      get "/api/v1/accounts/#{account.id}/tickets/#{ticket.id}",
          headers: agent.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:success)
      expect(response.parsed_body['tempo_liquido_segundos']).to eq(0)
    end
  end
end
