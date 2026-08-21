json.array! @ticket_statuses do |ticket_status|
  json.partial! 'api/v1/models/ticket_status', formats: [:json], resource: ticket_status
end
