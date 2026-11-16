# Allowlist of MCP tools exposed for tickets. Each tool maps to an existing REST
# route, so audit logs, automations and timers keep running through the regular
# controllers. Archive / unarchive / destroy are intentionally NOT listed.
class TicketsMcp::ToolRegistry
  TICKET_FIELDS = {
    'titulo' => { 'type' => 'string', 'description' => 'Ticket title' },
    'descricao' => { 'type' => 'string', 'description' => 'Ticket description' },
    'prioridade' => { 'type' => 'string', 'enum' => %w[baixa media alta critica], 'description' => 'Priority' },
    'responsavel_id' => { 'type' => 'integer', 'description' => 'User id of the owner (required on create)' },
    'team_id' => { 'type' => 'integer', 'description' => 'Team id; also sets the sector' },
    'conversation_id' => { 'type' => 'integer', 'description' => 'Linked conversation id' },
    'contact_id' => { 'type' => 'integer', 'description' => 'Linked contact id' },
    'categoria' => { 'type' => 'string', 'description' => 'Category' }
  }.freeze

  ID_PROPERTY = { 'id' => { 'type' => 'integer', 'description' => 'Ticket id' } }.freeze
  LIST_FILTERS = %w[q team_id contact_id conversation_id assigned_to_me exclude_status].freeze
  DEFAULT_LIMIT = 25

  Tool = Struct.new(:name, :description, :properties, :required, :verb, :path, :build, keyword_init: true) do
    def input_schema
      { 'type' => 'object', 'properties' => properties, 'required' => required }
    end

    def definition
      { 'name' => name, 'description' => description, 'inputSchema' => input_schema }
    end
  end

  def self.tools
    @tools ||= build_tools.index_by(&:name).freeze
  end

  def self.find(name)
    tools[name.to_s]
  end

  def self.definitions
    tools.values.map(&:definition)
  end

  def self.build_tools
    [
      list_tickets, show_ticket, ticket_timeline, ticket_audit_logs, list_ticket_statuses,
      create_ticket, update_ticket, change_ticket_status, add_ticket_comment
    ]
  end

  def self.list_tickets # rubocop:disable Metrics/MethodLength
    Tool.new(
      name: 'list_tickets',
      description: 'List tickets of the account (newest first, archived tickets are never returned). ' \
                   'Use q to search by id, title, description or contact name.',
      properties: {
        'q' => { 'type' => 'string' },
        'team_id' => { 'type' => 'integer' },
        'contact_id' => { 'type' => 'integer' },
        'conversation_id' => { 'type' => 'integer' },
        'assigned_to_me' => { 'type' => 'boolean' },
        'exclude_status' => { 'type' => 'string', 'description' => 'status_macro value to leave out' },
        'limit' => { 'type' => 'integer', 'minimum' => 1, 'maximum' => 100, 'default' => DEFAULT_LIMIT }
      },
      required: [], verb: :get, path: 'tickets',
      build: lambda { |args|
        query = args.slice(*LIST_FILTERS).compact_blank
        query['limit'] = (args['limit'].presence || DEFAULT_LIMIT).to_i.clamp(1, 100)
        { query: query }
      }
    )
  end

  def self.show_ticket
    Tool.new(name: 'get_ticket', description: 'Get one ticket with assignments, timers, worklogs and labels.',
             properties: ID_PROPERTY, required: ['id'], verb: :get, path: 'tickets/%<id>s',
             build: ->(_args) { {} })
  end

  def self.ticket_timeline
    Tool.new(name: 'get_ticket_timeline', description: 'Read the ticket timeline (comments, status and sector changes, worklogs).',
             properties: ID_PROPERTY, required: ['id'], verb: :get, path: 'tickets/%<id>s/timeline',
             build: ->(_args) { {} })
  end

  def self.ticket_audit_logs
    Tool.new(name: 'get_ticket_audit_logs', description: 'Read the ticket audit log.',
             properties: ID_PROPERTY, required: ['id'], verb: :get, path: 'tickets/%<id>s/audit_logs',
             build: ->(_args) { {} })
  end

  def self.list_ticket_statuses
    Tool.new(name: 'list_ticket_statuses', description: 'List the ticket statuses (Kanban columns) of the account.',
             properties: {}, required: [], verb: :get, path: 'ticket_statuses', build: ->(_args) { {} })
  end

  def self.create_ticket
    Tool.new(
      name: 'create_ticket',
      description: 'Create a ticket. titulo, descricao and responsavel_id are required.',
      properties: TICKET_FIELDS.merge('ticket_status_id' => { 'type' => 'integer', 'description' => 'Initial status id' }),
      required: %w[titulo descricao responsavel_id], verb: :post, path: 'tickets',
      build: ->(args) { { body: { 'ticket' => args.slice(*TICKET_FIELDS.keys, 'ticket_status_id').compact } } }
    )
  end

  def self.update_ticket
    Tool.new(
      name: 'update_ticket',
      description: 'Update ticket fields. To move a ticket between statuses use change_ticket_status.',
      properties: ID_PROPERTY.merge(TICKET_FIELDS), required: ['id'], verb: :patch, path: 'tickets/%<id>s',
      build: ->(args) { { body: { 'ticket' => args.slice(*TICKET_FIELDS.keys).compact } } }
    )
  end

  def self.change_ticket_status
    Tool.new(
      name: 'change_ticket_status',
      description: 'Move a ticket to another status (closes active timers, writes timeline/audit, runs automations).',
      properties: ID_PROPERTY.merge('ticket_status_id' => { 'type' => 'integer' }),
      required: %w[id ticket_status_id], verb: :patch, path: 'tickets/%<id>s/ticket_status',
      build: ->(args) { { body: { 'ticket_status_id' => args['ticket_status_id'] } } }
    )
  end

  def self.add_ticket_comment
    Tool.new(
      name: 'add_ticket_comment', description: 'Add a comment to the ticket timeline.',
      properties: ID_PROPERTY.merge('texto' => { 'type' => 'string', 'description' => 'Comment text' }),
      required: %w[id texto], verb: :post, path: 'tickets/%<id>s/comments',
      build: ->(args) { { body: { 'texto' => args['texto'] } } }
    )
  end

  private_class_method :build_tools, :list_tickets, :show_ticket, :ticket_timeline, :ticket_audit_logs,
                       :list_ticket_statuses, :create_ticket, :update_ticket, :change_ticket_status, :add_ticket_comment
end
