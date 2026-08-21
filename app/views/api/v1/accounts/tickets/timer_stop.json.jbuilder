if @worklog
  json.worklog do
    json.partial! 'api/v1/models/worklog', formats: [:json], resource: @worklog
  end
else
  json.worklog nil
end
