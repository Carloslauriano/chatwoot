class Api::V1::Accounts::WorklogsController < Api::V1::Accounts::BaseController
  before_action :fetch_ticket
  before_action :fetch_worklog, only: [:update, :destroy]
  before_action :check_ticket_authorization
  before_action :ensure_admin, only: [:destroy]

  # US13: adicionar tempo manualmente — sempre marcado como origem "manual" e auditado.
  def create
    @worklog = @ticket.worklogs.new(worklog_params.merge(account: Current.account, origem: :manual, editado_manualmente: true))
    @worklog.colaborador_id ||= Current.user.id
    @worklog.save!
    @ticket.ticket_timeline_events.create!(
      account: Current.account, tipo_evento: :worklog_manual, origem: :interno, autor_id: Current.user.id,
      payload: { worklog_id: @worklog.id, duracao_segundos: @worklog.duracao_segundos }
    )
    log_audit!('worklog_created')
  end

  # US13: edição manual de um worklog existente — sempre registrada em audit_logs.
  def update
    valor_antes = @worklog.duracao_segundos
    @worklog.update!(worklog_params.merge(editado_manualmente: true))
    log_audit!('worklog_edited', campo: 'duracao_segundos', antes: valor_antes, depois: @worklog.duracao_segundos)
  end

  # Apagar um registro de tempo é restrito a administradores.
  def destroy
    valor_antes = @worklog.duracao_segundos
    @worklog.destroy!
    log_audit!('worklog_deleted', campo: 'duracao_segundos', antes: valor_antes)
    head :no_content
  end

  private

  def fetch_ticket
    @ticket = Current.account.tickets.find(params[:ticket_id])
  end

  def fetch_worklog
    @worklog = @ticket.worklogs.find(params[:id])
  end

  def check_ticket_authorization
    check_authorization(Ticket)
  end

  def ensure_admin
    raise Pundit::NotAuthorizedError unless Current.account_user.administrator?
  end

  def worklog_params
    params.require(:worklog).permit(:colaborador_id, :inicio, :fim, :duracao_segundos, :motivo)
  end

  def log_audit!(acao, campo: nil, antes: nil, depois: nil)
    @ticket.ticket_audit_logs.create!(
      account: Current.account, autor_id: Current.user.id, acao: acao, campo: campo,
      valor_antes: antes, valor_depois: depois
    )
  end
end
