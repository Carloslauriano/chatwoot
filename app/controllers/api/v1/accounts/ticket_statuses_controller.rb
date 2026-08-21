# Colunas do Kanban configuráveis, vinculáveis a um ou mais times.
class Api::V1::Accounts::TicketStatusesController < Api::V1::Accounts::BaseController
  before_action :fetch_ticket_status, only: [:update, :destroy]
  before_action :check_authorization

  def index
    @ticket_statuses = Current.account.ticket_statuses
  end

  def create
    @ticket_status = Current.account.ticket_statuses.new(ticket_status_params)
    @ticket_status.save!
    sync_team_positions!
  end

  def update
    @ticket_status.update!(ticket_status_params)
    sync_team_positions!
  end

  def destroy
    @ticket_status.destroy!
    head :no_content
  end

  private

  def fetch_ticket_status
    @ticket_status = Current.account.ticket_statuses.find(params[:id])
  end

  def ticket_status_params
    params.require(:ticket_status).permit(:name, :position, :color, :is_default)
  end

  # team_positions: [{ team_id:, position: }] — a posição de uma coluna pode
  # ser diferente por time (sobrepõe TicketStatus#position quando o Kanban
  # está filtrado por um time específico). Tratado fora de ticket_status_params
  # porque não é um atributo direto do TicketStatus, e sim do join
  # ticket_status_teams.
  def sync_team_positions!
    return unless params[:ticket_status][:team_positions]

    team_positions = params[:ticket_status].require(:team_positions).map do |tp|
      tp.permit(:team_id, :position)
    end
    incoming_team_ids = team_positions.map { |tp| tp[:team_id].to_i }

    @ticket_status.ticket_status_teams.where.not(team_id: incoming_team_ids).destroy_all
    team_positions.each do |tp|
      tst = @ticket_status.ticket_status_teams.find_or_initialize_by(team_id: tp[:team_id])
      tst.position = tp[:position] || 0
      tst.save!
    end
  end
end
