# Runs an allowlisted tool against the regular REST API in-process, reusing the
# caller's access token. Only routes declared in ToolRegistry can be reached.
class TicketsMcp::Dispatcher
  Result = Struct.new(:status, :body, keyword_init: true) do
    def success?
      status.between?(200, 299)
    end
  end

  class InvalidArguments < StandardError; end

  CURRENT_FIELDS = %i[user account account_user executed_by contact inbox originated_from_ui].freeze

  def initialize(request:, account_id:, token:)
    @request = request
    @account_id = account_id
    @token = token
  end

  def call(tool, arguments)
    args = (arguments || {}).to_h.stringify_keys
    missing = tool.required.select { |key| args[key].blank? }
    raise InvalidArguments, "Missing required arguments: #{missing.join(', ')}" if missing.any?

    perform(tool, args)
  end

  private

  def perform(tool, args)
    options = tool.build.call(args)
    path = "/api/v1/accounts/#{Integer(@account_id)}/#{format(tool.path, id: id_from(args, tool))}"
    path += "?#{options[:query].to_query}" if options[:query].present?

    # The inner request resets/overwrites Current; restore it for the outer request.
    saved = CURRENT_FIELDS.index_with { |field| Current.public_send(field) }
    begin
      run_rack(tool.verb, path, options[:body])
    ensure
      Current.reset
      saved.each { |field, value| Current.public_send(:"#{field}=", value) }
    end
  end

  def id_from(args, tool)
    return nil unless tool.path.include?('%<id>s')

    Integer(args['id'], exception: false) || raise(InvalidArguments, 'id must be an integer')
  end

  def run_rack(verb, path, body)
    env = Rack::MockRequest.env_for(
      path,
      :method => verb.to_s.upcase, :input => body&.to_json.to_s,
      'CONTENT_TYPE' => 'application/json', 'HTTP_ACCEPT' => 'application/json',
      'HTTP_API_ACCESS_TOKEN' => @token, 'HTTP_HOST' => @request.host_with_port,
      'REMOTE_ADDR' => @request.remote_ip, 'HTTP_X_FORWARDED_PROTO' => @request.scheme,
      'rack.url_scheme' => @request.scheme
    )
    status, _headers, response = Rails.application.call(env)
    text = +''
    response.each { |chunk| text << chunk }
    response.close if response.respond_to?(:close)
    Result.new(status: status, body: text)
  end
end
