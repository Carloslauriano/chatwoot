json.active_timer do
  json.partial! 'api/v1/models/active_timer', formats: [:json], resource: @active_timer
end
