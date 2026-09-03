module TicketTimelineSerializable
  extend ActiveSupport::Concern

  private

  def serialize_ticket_event(event)
    {
      id: "event-#{event.id}",
      tipo_evento: event.tipo_evento,
      origem: event.origem,
      autor_id: event.autor_id,
      autor_nome: user_name_for(event.autor_id),
      autor_avatar_url: user_avatar_url_for(event.autor_id),
      payload: event.payload,
      created_at: event.created_at,
    }
  end

  def user_name_for(user_id)
    return nil if user_id.blank?

    User.find_by(id: user_id)&.name
  end

  def user_avatar_url_for(user_id)
    return nil if user_id.blank?

    User.find_by(id: user_id)&.avatar_url
  end
end
