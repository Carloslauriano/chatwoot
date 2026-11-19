# MCP server (Streamable HTTP, JSON-RPC 2.0) exposing ticket tools to an external AI.
# Authenticates with the user's own api access token; every tool call is forwarded to
# the regular REST API with that same token, so account scoping and policies still apply.
class Api::V1::Accounts::McpController < Api::V1::Accounts::BaseController
  SUPPORTED_VERSIONS = %w[2025-06-18 2025-03-26 2024-11-05].freeze

  before_action :require_access_token

  # Not a REST resource: no strong params / policy, each tool call is authorized by the inner route.
  def handle # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    message = JSON.parse(request.raw_post)
    return render_rpc_error(nil, -32_600, 'Invalid Request') unless message.is_a?(Hash) || message.is_a?(Array)

    if message.is_a?(Array)
      responses = message.filter_map { |item| process_message(item) }
      responses.empty? ? head(:accepted) : render(json: responses)
    else
      response_body = process_message(message)
      response_body ? render(json: response_body) : head(:accepted)
    end
  rescue JSON::ParserError
    render_rpc_error(nil, -32_700, 'Parse error')
  end

  def method_not_allowed
    head :method_not_allowed
  end

  private

  def require_access_token
    return if authenticate_by_access_token?

    render_unauthorized('The MCP endpoint requires an api access token')
  end

  # Not named `process`: that would override AbstractController::Base#process (action dispatch).
  def process_message(message) # rubocop:disable Metrics/CyclomaticComplexity
    return rpc_error(nil, -32_600, 'Invalid Request') unless message.is_a?(Hash)

    id = message['id']
    return nil if message['method'].to_s.start_with?('notifications/') || (id.nil? && message.key?('method'))

    result = dispatch_method(message['method'], message['params'] || {})
    return rpc_error(id, -32_601, "Method not found: #{message['method']}") if result == :unknown

    { 'jsonrpc' => '2.0', 'id' => id, 'result' => result }
  rescue ActionController::BadRequest, TicketsMcp::Dispatcher::InvalidArguments => e
    rpc_error(id, -32_602, e.message)
  end

  def dispatch_method(method, params)
    case method
    when 'initialize' then initialize_result(params)
    when 'ping' then {}
    when 'tools/list' then { 'tools' => TicketsMcp::ToolRegistry.definitions }
    when 'tools/call' then call_tool(params)
    else :unknown
    end
  end

  def initialize_result(params)
    requested = params['protocolVersion']
    {
      'protocolVersion' => SUPPORTED_VERSIONS.include?(requested) ? requested : SUPPORTED_VERSIONS.first,
      'capabilities' => { 'tools' => { 'listChanged' => false } },
      'serverInfo' => { 'name' => 'chatwoot-tickets', 'version' => '1.0.0' },
      'instructions' => 'Manage and read support tickets, including time tracking (timers and worklogs). ' \
                        'Archiving and deleting tickets is not available.'
    }
  end

  def call_tool(params)
    tool = TicketsMcp::ToolRegistry.find(params['name'])
    raise ActionController::BadRequest, "Unknown tool: #{params['name']}" unless tool

    arguments = params['arguments']
    raise ActionController::BadRequest, 'arguments must be an object' unless arguments.nil? || arguments.is_a?(Hash)

    result = dispatcher.call(tool, arguments)
    { 'content' => [{ 'type' => 'text', 'text' => result.body.presence || '{}' }], 'isError' => !result.success? }
  end

  def dispatcher
    @dispatcher ||= TicketsMcp::Dispatcher.new(request: request, account_id: params[:account_id], token: @access_token.token)
  end

  def rpc_error(id, code, message)
    { 'jsonrpc' => '2.0', 'id' => id, 'error' => { 'code' => code, 'message' => message } }
  end

  def render_rpc_error(id, code, message)
    render json: rpc_error(id, code, message)
  end
end
