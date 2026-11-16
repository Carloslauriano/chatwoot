# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Tickets MCP API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:token_headers) { { 'api_access_token' => agent.access_token.token } }
  let(:url) { "/api/v1/accounts/#{account.id}/mcp" }
  let!(:status) { create(:ticket_status, account: account) }

  def rpc(method, params = {}, headers: token_headers, id: 1)
    post url, params: { jsonrpc: '2.0', id: id, method: method, params: params }.to_json,
              headers: headers.merge('CONTENT_TYPE' => 'application/json')
  end

  def tool_call(name, arguments = {})
    rpc('tools/call', { name: name, arguments: arguments })
    response.parsed_body['result']
  end

  def tool_json(result)
    JSON.parse(result['content'].first['text'])
  end

  describe 'protocol' do
    it 'answers initialize' do
      rpc('initialize', { protocolVersion: '2025-03-26' })

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['result']).to include('protocolVersion' => '2025-03-26')
    end

    it 'accepts notifications without a body response' do
      post url, params: { jsonrpc: '2.0', method: 'notifications/initialized' }.to_json,
                headers: token_headers.merge('CONTENT_TYPE' => 'application/json')

      expect(response).to have_http_status(:accepted)
    end

    it 'never lists archive or delete tools' do
      rpc('tools/list')

      names = response.parsed_body['result']['tools'].pluck('name')
      expect(names).to include('list_tickets', 'create_ticket', 'update_ticket', 'add_ticket_comment')
      expect(names.grep(/archive|delete|destroy|remove/)).to be_empty
    end

    it 'returns an error for unknown tools such as archive_ticket' do
      rpc('tools/call', { name: 'archive_ticket', arguments: { id: 1 } })

      expect(response.parsed_body['error']['code']).to eq(-32_602)
    end

    it 'rejects GET' do
      get url, headers: token_headers

      expect(response).to have_http_status(:method_not_allowed)
    end
  end

  describe 'authentication' do
    it 'rejects an invalid token' do
      rpc('tools/list', headers: { 'api_access_token' => 'nope' })

      expect(response).to have_http_status(:unauthorized)
    end

    it 'rejects a user that does not belong to the account' do
      outsider = create(:user)

      rpc('tools/list', headers: { 'api_access_token' => outsider.access_token.token })

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'ticket tools' do
    let!(:ticket) { create(:ticket, account: account, responsavel: agent) }

    it 'lists and reads tickets' do
      list = tool_json(tool_call('list_tickets', { q: 'Nota' }))
      expect(list.to_s).to include(ticket.titulo)

      show = tool_call('get_ticket', { id: ticket.id })
      expect(show['isError']).to be(false)
      expect(tool_json(show)['id']).to eq(ticket.id)
    end

    it 'does not return archived tickets even if archived is passed' do
      ticket.update!(archived: true)

      result = tool_call('list_tickets', { archived: true })

      expect(result['isError']).to be(false)
      expect(tool_json(result).to_s).not_to include(ticket.titulo)
    end

    it 'creates, updates, changes status and comments' do
      created = tool_call('create_ticket', { titulo: 'Via MCP', descricao: 'IA', responsavel_id: agent.id })
      expect(created['isError']).to be(false)
      id = tool_json(created)['id']

      updated = tool_call('update_ticket', { id: id, prioridade: 'alta', archived: true })
      expect(updated['isError']).to be(false)
      expect(Ticket.find(id)).to have_attributes(prioridade: 'alta', archived: false)

      moved = tool_call('change_ticket_status', { id: id, ticket_status_id: status.id })
      expect(moved['isError']).to be(false)
      expect(Ticket.find(id).ticket_status_id).to eq(status.id)

      comment = tool_call('add_ticket_comment', { id: id, texto: 'ok' })
      expect(comment['isError']).to be(false)
      expect(Ticket.find(id).ticket_timeline_events.where(tipo_evento: :comentario).count).to eq(1)
    end

    it 'reports validation errors as tool errors' do
      result = tool_call('create_ticket', { titulo: 'x', descricao: 'y', responsavel_id: 0 })

      expect(result['isError']).to be(true)
    end

    it 'cannot reach tickets of another account' do
      other = create(:ticket)

      result = tool_call('get_ticket', { id: other.id })

      expect(result['isError']).to be(true)
    end

    it 'reports missing required arguments' do
      rpc('tools/call', { name: 'get_ticket', arguments: {} })

      expect(response.parsed_body['error']['code']).to eq(-32_602)
    end
  end
end
