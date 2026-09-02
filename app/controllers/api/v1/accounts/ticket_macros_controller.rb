# Ações em lote reutilizáveis sobre Tickets (status, time, labels, prioridade,
# arquivamento) — ver TicketMacros::RunnerService.
class Api::V1::Accounts::TicketMacrosController < Api::V1::Accounts::BaseController
  before_action :fetch_ticket_macro, only: [:update, :destroy, :execute]
  before_action :check_authorization

  def index
    @ticket_macros = Current.account.ticket_macros
  end

  def create
    @ticket_macro = Current.account.ticket_macros.new(ticket_macro_params.merge(created_by_id: Current.user.id))
    @ticket_macro.save!
  end

  def update
    @ticket_macro.update!(ticket_macro_params.merge(updated_by_id: Current.user.id))
  end

  def destroy
    @ticket_macro.destroy!
    head :no_content
  end

  def execute
    ticket = Current.account.tickets.find(params.require(:ticket_id))
    TicketMacros::RunnerService.new(@ticket_macro, ticket, current_user: Current.user).perform
    render json: { success: true }
  end

  private

  def fetch_ticket_macro
    @ticket_macro = Current.account.ticket_macros.find(params[:id])
  end

  def ticket_macro_params
    params.require(:ticket_macro).permit(:name, actions: [:action_name, { action_params: [] }])
  end
end
