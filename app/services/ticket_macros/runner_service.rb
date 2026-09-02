module TicketMacros
  # Executa as ações de um TicketMacro sobre um Ticket, na ordem em que
  # aparecem em `actions`. Reaproveita os mesmos efeitos colaterais de
  # TicketsController#ticket_status / #transfer (automação + timeline)
  # para as ações que os espelham.
  class RunnerService
    def initialize(ticket_macro, ticket, current_user:)
      @ticket_macro = ticket_macro
      @ticket = ticket
      @current_user = current_user
    end

    def perform
      @ticket_macro.actions.each { |action| apply_action(action) }
      log_audit!
    end

    private

    def apply_action(action)
      action_params = Array(action['action_params'])

      case action['action_name']
      when 'change_ticket_status' then change_ticket_status(action_params)
      when 'assign_team' then assign_team(action_params)
      when 'add_label' then add_label(action_params)
      when 'remove_label' then remove_label(action_params)
      when 'change_priority' then change_priority(action_params)
      when 'archive_ticket' then @ticket.update!(archived: true)
      when 'unarchive_ticket' then @ticket.update!(archived: false)
      end
    end

    def change_ticket_status(action_params)
      status = @ticket.account.ticket_statuses.find_by(id: action_params.first)
      return unless status

      nome_antes = @ticket.ticket_status&.name
      @ticket.update!(ticket_status: status)
      TicketAutomationRules::RunnerService.new(@ticket, event_name: 'ticket_status_changed').perform
      @ticket.ticket_timeline_events.create!(
        account: @ticket.account, tipo_evento: :status_macro_changed, origem: :interno, autor_id: @current_user.id,
        payload: { status_macro_antes: nome_antes, status_macro_depois: status.name }
      )
    end

    def assign_team(action_params)
      team = @ticket.account.teams.find_by(id: action_params.first)
      return unless team

      @ticket.update!(team: team, setor_atual: team.name)
      TicketAutomationRules::RunnerService.new(@ticket, event_name: 'ticket_team_changed').perform
    end

    def add_label(action_params)
      label = action_params.first
      return if label.blank?

      @ticket.add_labels([label])
    end

    def remove_label(action_params)
      label = action_params.first
      return if label.blank?

      @ticket.update!(label_list: @ticket.label_list - [label])
    end

    def change_priority(action_params)
      prioridade = action_params.first
      return if prioridade.blank?

      @ticket.update!(prioridade: prioridade)
    end

    def log_audit!
      @ticket.ticket_audit_logs.create!(
        account: @ticket.account, autor_id: @current_user.id, acao: 'ticket_macro_executed',
        campo: 'ticket_macro', valor_antes: nil, valor_depois: @ticket_macro.name
      )
    end
  end
end
