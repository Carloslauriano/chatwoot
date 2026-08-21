json.id resource.id
json.account_id resource.account_id
json.conversation_id resource.conversation_id
json.contact_id resource.contact_id
json.responsavel_id resource.responsavel_id
json.responsavel_nome resource.responsavel&.name
json.responsavel_avatar_url resource.responsavel&.avatar_url
json.titulo resource.titulo
json.descricao resource.descricao
json.categoria resource.categoria
json.prioridade resource.prioridade
json.setor_atual resource.setor_atual
json.team_id resource.team_id
json.team_name resource.team&.name
json.ticket_status_id resource.ticket_status_id
json.ticket_status_name resource.ticket_status&.name
json.status_macro resource.status_macro
json.resolvido_em resource.resolvido_em
json.tempo_bruto_segundos resource.tempo_bruto_segundos
json.tempo_liquido_segundos resource.tempo_liquido_segundos
json.label_list resource.label_list
json.assignments do
  json.array! resource.ticket_assignments do |assignment|
    json.id assignment.id
    json.colaborador_id assignment.colaborador_id
    json.colaborador_nome User.find_by(id: assignment.colaborador_id)&.name
    json.status_micro assignment.status_micro
  end
end
json.active_timers do
  json.array! resource.active_timers do |timer|
    json.id timer.id
    json.colaborador_id timer.colaborador_id
    json.iniciado_em timer.iniciado_em
  end
end
json.created_at resource.created_at
json.updated_at resource.updated_at
