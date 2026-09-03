class Api::V1::Accounts::Tickets::CommentsController < Api::V1::Accounts::BaseController
  include TicketTimelineSerializable

  before_action :fetch_ticket
  before_action :check_ticket_authorization

  def create
    @event = @ticket.ticket_timeline_events.create!(
      account: Current.account, tipo_evento: :comentario, origem: :interno, autor_id: Current.user.id,
      payload: { texto: params.require(:texto) }
    )
    @event = serialize_ticket_event(@event)
  end

  private

  def fetch_ticket
    @ticket = Current.account.tickets.find(params[:ticket_id])
  end

  def check_ticket_authorization
    check_authorization(Ticket)
  end
end
