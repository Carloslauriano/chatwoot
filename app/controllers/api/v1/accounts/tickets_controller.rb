class Api::V1::Accounts::TicketsController < Api::V1::Accounts::BaseController
  before_action :fetch_ticket, only: [:show, :update, :link_conversation, :transfer, :ticket_status,
                                       :timer_start, :timer_stop, :timeline, :audit_logs, :archive, :unarchive]
  before_action :check_authorization

  # Sem filtros: retorna todos os tickets da conta (página "Tickets").
  # team_id[]: usado pela página "Kanban". conversation_id/contact_id:
  # usados para checar se já existe ticket vinculado (TicketsList,
  # OpenTicketButton, LinkTicket) — sem isso, qualquer ticket da conta
  # era retornado e o frontend pegava o primeiro, errado, da lista.
  def index
    @tickets = Current.account.tickets
    @tickets = @tickets.where(team_id: params[:team_id]) if params[:team_id].present?
    @tickets = @tickets.where(conversation_id: params[:conversation_id]) if params[:conversation_id].present?
    @tickets = @tickets.where(contact_id: params[:contact_id]) if params[:contact_id].present?
    @tickets = @tickets.where.not(status_macro: params[:exclude_status]) if params[:exclude_status].present?
    @tickets = @tickets.where(archived: params[:archived].present? ? ActiveModel::Type::Boolean.new.cast(params[:archived]) : false)
  end

  def show; end

  def create
    @ticket = Current.account.tickets.new(ticket_params)
    @ticket.contact_id ||= @ticket.conversation&.contact_id
    @ticket.categoria ||= ''
    @ticket.ticket_status_id ||= Current.account.ticket_statuses.find_by(is_default: true)&.id
    if @ticket.team_id.present?
      @ticket.setor_atual = Team.find(@ticket.team_id).name
    else
      @ticket.setor_atual ||= 'suporte'
    end
    @ticket.save!
    log_audit!(@ticket, 'ticket_created')
  end

  def update
    @ticket.update!(ticket_params)
  end

  # US01: vincular a um ticket já existente a partir de outra conversa do
  # mesmo contato. G1: bloqueia se o ticket já estiver resolvido.
  def link_conversation
    if @ticket.resolvido?
      render json: { error: 'Ticket já está resolvido. Crie um novo ticket.' }, status: :conflict
      return
    end

    @ticket.update!(conversation_id: params[:conversation_id])
    log_audit!(@ticket, 'conversation_linked', campo: 'conversation_id', depois: params[:conversation_id])
  end

  # US05 + G2: transferir setor pausa (sem gerar worklog) qualquer timer ativo
  # ligado a este ticket, para qualquer colaborador.
  def transfer
    setor_origem = @ticket.setor_atual
    team_destino = params[:team_id].present? ? Current.account.teams.find(params[:team_id]) : nil
    setor_destino = team_destino&.name || params.require(:setor_destino)

    ActiveRecord::Base.transaction do
      @ticket.active_timers.find_each { |timer| pause_timer_without_worklog(timer) }
      @ticket.update!(setor_atual: setor_destino, team: team_destino || @ticket.team)
      TicketAutomationRules::RunnerService.new(@ticket, event_name: 'ticket_team_changed').perform if team_destino
      @ticket.ticket_timeline_events.create!(
        account: Current.account, tipo_evento: :setor_changed, origem: :interno, autor_id: Current.user.id,
        payload: { setor_origem: setor_origem, setor_destino: setor_destino }
      )
    end

    log_audit!(@ticket, 'setor_changed', campo: 'setor_atual', antes: setor_origem, depois: setor_destino)
  end

  # US06 + G3: sem bloqueio por status_micro pendente — decisão de produto confirmada.
  # Colunas do Kanban agora são TicketStatus configuráveis, não mais o enum
  # status_macro (mantido só como legado não usado).
  def ticket_status
    novo_status = Current.account.ticket_statuses.find(params.require(:ticket_status_id))
    nome_antes = @ticket.ticket_status&.name
    @ticket.update!(ticket_status: novo_status)
    TicketAutomationRules::RunnerService.new(@ticket, event_name: 'ticket_status_changed').perform
    @ticket.ticket_timeline_events.create!(
      account: Current.account, tipo_evento: :status_macro_changed, origem: :interno, autor_id: Current.user.id,
      payload: { status_macro_antes: nome_antes, status_macro_depois: novo_status.name }
    )
    log_audit!(@ticket, 'status_macro_changed', campo: 'ticket_status', antes: nome_antes, depois: novo_status.name)
  end

  # RN01: um colaborador só pode ter 1 timer ativo por vez, garantido pela
  # constraint UNIQUE(colaborador_id) — tratamos concorrência com 1 retry.
  def timer_start
    @active_timer = start_timer_for(Current.user.id, retry_on_conflict: true)
    ensure_assignment!(Current.user.id).update!(status_micro: :fazendo)
  end

  # decisao: "finalizado" cria Worklog; "pausado" apenas remove o timer (G4/G5).
  def timer_stop
    active_timer = @ticket.active_timers.find_by!(colaborador_id: Current.user.id)
    decisao = params.require(:decisao)

    if decisao == 'finalizado'
      @worklog = close_timer_with_worklog(active_timer)
      ensure_assignment!(Current.user.id).update!(status_micro: :finalizado)
    else
      active_timer.destroy!
    end
  end

  def timeline
    @timeline_events = @ticket.ticket_timeline_events
                               .map { |event| serialize_ticket_event(event) }
                               .sort_by { |event| event[:created_at] }
                               .reverse
  end

  def audit_logs
    @audit_logs = @ticket.ticket_audit_logs.order(created_at: :desc)
  end

  # Admin-only (ver TicketPolicy#archive?). Ticket arquivado some de todas as
  # listas (Kanban, página Tickets, widgets) via filtro padrão do #index.
  def archive
    @ticket.update!(archived: true)
    log_audit!(@ticket, 'archived')
  end

  def unarchive
    @ticket.update!(archived: false)
    log_audit!(@ticket, 'unarchived')
  end

  private

  def fetch_ticket
    @ticket = Current.account.tickets.find(params[:id])
  end

  def ticket_params
    params.require(:ticket).permit(:conversation_id, :contact_id, :titulo, :descricao, :categoria, :prioridade,
                                    :setor_atual, :responsavel_id, :team_id)
  end

  def ensure_assignment!(colaborador_id)
    @ticket.ticket_assignments.find_or_create_by!(account: Current.account, colaborador_id: colaborador_id)
  end

  def start_timer_for(colaborador_id, retry_on_conflict:)
    ActiveRecord::Base.transaction do
      existing = ActiveTimer.find_by(colaborador_id: colaborador_id)
      return existing if existing && existing.ticket_id == @ticket.id

      pause_timer_without_worklog(existing) if existing
      ActiveTimer.create!(account: Current.account, colaborador_id: colaborador_id, ticket: @ticket, iniciado_em: Time.current)
    end
  rescue ActiveRecord::RecordNotUnique
    raise unless retry_on_conflict

    start_timer_for(colaborador_id, retry_on_conflict: false)
  end

  # G4/G5: pausa automática (RN01 ou transferência de setor) nunca gera Worklog.
  def pause_timer_without_worklog(active_timer)
    active_timer.destroy!
  end

  def close_timer_with_worklog(active_timer)
    inicio = active_timer.iniciado_em
    fim = Time.current
    worklog = @ticket.worklogs.create!(
      account: Current.account, colaborador_id: active_timer.colaborador_id,
      inicio: inicio, fim: fim, duracao_segundos: (fim - inicio).to_i, origem: :timer
    )
    @ticket.ticket_timeline_events.create!(
      account: Current.account, tipo_evento: :worklog, origem: :sistema, autor_id: active_timer.colaborador_id,
      payload: { worklog_id: worklog.id, duracao_segundos: worklog.duracao_segundos }
    )
    active_timer.destroy!
    worklog
  end

  def log_audit!(ticket, acao, campo: nil, antes: nil, depois: nil)
    ticket.ticket_audit_logs.create!(
      account: Current.account, autor_id: Current.user.id, acao: acao, campo: campo,
      valor_antes: antes, valor_depois: depois
    )
  end

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
