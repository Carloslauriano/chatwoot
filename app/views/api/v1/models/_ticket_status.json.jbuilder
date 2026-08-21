json.id resource.id
json.account_id resource.account_id
json.name resource.name
json.position resource.position
json.color resource.color
json.is_default resource.is_default
json.team_ids resource.team_ids
json.team_positions do
  json.array! resource.ticket_status_teams do |tst|
    json.team_id tst.team_id
    json.position tst.position
  end
end
json.created_at resource.created_at
json.updated_at resource.updated_at
