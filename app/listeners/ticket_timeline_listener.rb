class TicketTimelineListener < BaseListener
  # US04 (revertida): a timeline do ticket não deve mais incluir as
  # mensagens da conversa — só eventos internos do próprio ticket.
  def conversation_status_changed(event)
    conversation = extract_conversation_and_account(event)[0]
    ticket = Ticket.find_by(conversation_id: conversation.id)
    return unless ticket

    sync_status_macro(ticket, conversation)

    ticket.ticket_timeline_events.create!(
      account: ticket.account,
      tipo_evento: :status_macro_changed,
      origem: :sistema,
      payload: { conversation_status: conversation.status }
    )
  end

  private

  # A tela "Tickets" (painel de status) e o guard de link_conversation
  # dependem de status_macro/resolvido?, mas nada mais no sistema o
  # atualiza — o Kanban foi migrado para TicketStatus configurável e não
  # mexe nesse enum. Sem isso, um ticket permanece "Caixa de Entrada" para
  # sempre mesmo depois da conversa ser resolvida.
  def sync_status_macro(ticket, conversation)
    deveria_estar_resolvido = conversation.status == 'resolved'
    return if ticket.resolvido? == deveria_estar_resolvido

    ticket.update!(status_macro: deveria_estar_resolvido ? :resolvido : :caixa_entrada)
  end
end
