class Api::V1::Accounts::TicketAssignmentsController < Api::V1::Accounts::BaseController
  before_action :fetch_ticket
  before_action :fetch_assignment, only: [:update, :destroy]
  before_action :check_ticket_authorization

  # Membros: qualquer colaborador do setor pode adicionar outro colaborador ao ticket.
  def create
    @assignment = @ticket.ticket_assignments.create!(colaborador_id: create_params[:colaborador_id])
    @ticket.ticket_timeline_events.create!(
      account: Current.account, tipo_evento: :membro_added, origem: :interno, autor_id: Current.user.id,
      payload: { colaborador_id: @assignment.colaborador_id }
    )
    @ticket.ticket_audit_logs.create!(
      account: Current.account, autor_id: Current.user.id, acao: 'membro_added',
      campo: 'colaborador_id', valor_depois: @assignment.colaborador_id
    )
  end

  # US07: status micro é individual por colaborador e não afeta o status macro do setor.
  def update
    valor_antes = @assignment.status_micro
    @assignment.update!(assignment_params)
    @ticket.ticket_timeline_events.create!(
      account: Current.account, tipo_evento: :status_micro_changed, origem: :interno, autor_id: Current.user.id,
      payload: { colaborador_id: @assignment.colaborador_id, status_micro_antes: valor_antes, status_micro_depois: @assignment.status_micro }
    )
    @ticket.ticket_audit_logs.create!(
      account: Current.account, autor_id: Current.user.id, acao: 'status_micro_changed',
      campo: 'status_micro', valor_antes: valor_antes, valor_depois: @assignment.status_micro
    )
  end

  def destroy
    colaborador_id = @assignment.colaborador_id
    @assignment.destroy!
    @ticket.ticket_timeline_events.create!(
      account: Current.account, tipo_evento: :membro_removed, origem: :interno, autor_id: Current.user.id,
      payload: { colaborador_id: colaborador_id }
    )
    @ticket.ticket_audit_logs.create!(
      account: Current.account, autor_id: Current.user.id, acao: 'membro_removed',
      campo: 'colaborador_id', valor_antes: colaborador_id
    )
    head :no_content
  end

  private

  def fetch_ticket
    @ticket = Current.account.tickets.find(params[:ticket_id])
  end

  def fetch_assignment
    @assignment = @ticket.ticket_assignments.find(params[:id])
  end

  def check_ticket_authorization
    check_authorization(Ticket)
  end

  def create_params
    params.require(:ticket_assignment).permit(:colaborador_id)
  end

  def assignment_params
    params.require(:ticket_assignment).permit(:status_micro)
  end
end
