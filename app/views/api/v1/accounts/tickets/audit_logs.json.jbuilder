json.array! @audit_logs do |log|
  json.partial! 'api/v1/models/ticket_audit_log', formats: [:json], resource: log
end
