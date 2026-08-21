class TicketTimelineListener < BaseListener
  # US04 / RNF performance: importa mensagens/mudanças de status da conversa
  # do Chatwoot para a timeline do ticket vinculado, em tempo real (síncrono,
  # sem fila intermediária).
  def message_created(event)
    message = extract_message_and_account(event)[0]
    ticket = Ticket.find_by(conversation_id: message.conversation_id)
    return unless ticket
    return unless message.incoming? || message.outgoing?

    ticket.ticket_timeline_events.create!(
      account: ticket.account,
      tipo_evento: :mensagem_cliente,
      origem: :chatwoot,
      autor_id: message.sender_id,
      payload: { message_id: message.id, content: message.content }
    )
  end

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
