json.array! @ticket_automation_rules do |ticket_automation_rule|
  json.partial! 'api/v1/models/ticket_automation_rule', formats: [:json], resource: ticket_automation_rule
end
