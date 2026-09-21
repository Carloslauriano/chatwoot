class Api::V1::Accounts::Tickets::AttachmentsController < Api::V1::Accounts::BaseController
  before_action :fetch_ticket
  before_action :check_ticket_authorization
  before_action :fetch_anexo, only: [:destroy]

  def create
    @ticket.anexos.attach(params[:anexos])
    @ticket.save!
  end

  def destroy
    @anexo.purge
    head :ok
  end

  private

  def fetch_ticket
    @ticket = Current.account.tickets.find(params[:ticket_id])
  end

  def fetch_anexo
    @anexo = @ticket.anexos.find(params[:id])
  end

  def check_ticket_authorization
    check_authorization(Ticket)
  end
end
