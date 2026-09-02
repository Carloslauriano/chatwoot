json.array! @ticket_macros do |ticket_macro|
  json.partial! 'api/v1/models/ticket_macro', formats: [:json], resource: ticket_macro
end
