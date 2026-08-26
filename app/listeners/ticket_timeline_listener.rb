class TicketTimelineListener < BaseListener
  # US04 (revertida): a timeline do ticket não deve mais incluir as
  # mensagens da conversa — só eventos internos do próprio ticket.
  def conversation_status_changed(event)
    conversation = extract_conversation_and_account(event)[0]
    ticket = Ticket.find_by(conversation_id: conversation.id)
    return unless ticket

    ticket.ticket_timeline_events.create!(
      account: ticket.account,
      tipo_evento: :status_macro_changed,
      origem: :sistema,
      payload: { conversation_status: conversation.status }
    )
  end
end
