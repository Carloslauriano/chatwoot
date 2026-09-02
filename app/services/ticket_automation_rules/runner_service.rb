module TicketAutomationRules
  # Avalia e executa as automações de ticket configuradas em
  # Settings > Automação de tickets. Chamado diretamente pelos controllers
  # depois de uma mudança de status ou de etiqueta (não existe um bus de
  # eventos tipo Wisper pro model Ticket, então isso é feito na mão aqui —
  # ver TicketsController#ticket_status e Tickets::LabelsController#create).
  #
  # Decisões de escopo: sem encadeamento (uma ação de automação não dispara
  # outra automação) e sem trilha de auditoria própria ainda (TicketAuditLog
  # exige autor_id, que não existe pra uma automação) — evolução natural se
  # precisar depois.
  class RunnerService
    def initialize(ticket, event_name:, label: nil)
      @ticket = ticket
      @event_name = event_name
      @label = label
    end

    def perform
      rules.each do |rule|
        next unless conditions_match?(rule)

        execute_actions(rule)
      end
    end

    private

    def rules
      @ticket.account.ticket_automation_rules.where(event_name: @event_name, active: true)
    end

    def conditions_match?(rule)
      conditions = rule.conditions || {}

      case @event_name
      when 'ticket_status_changed'
        return false if present_and_different?(conditions['to_ticket_status_id'], @ticket.ticket_status_id)
      when 'ticket_label_added'
        return false if conditions['label'].present? && conditions['label'] != @label
      when 'ticket_team_changed'
        return false if present_and_different?(conditions['to_team_id'], @ticket.team_id)
      end

      return false if present_and_different?(conditions['team_id'], @ticket.team_id)
      return false if present_and_different?(conditions['ticket_status_id'], @ticket.ticket_status_id)

      true
    end

    def present_and_different?(condition_value, ticket_value)
      condition_value.present? && condition_value.to_i != ticket_value.to_i
    end

    def execute_actions(rule)
      Array(rule.actions).each do |action|
        run_action(action['action_name'], action)
      rescue StandardError => e
        Rails.logger.error(
          "[TicketAutomationRule##{rule.id}] ação #{action['action_name']} falhou: #{e.message}"
        )
      end
    end

    def run_action(action_name, params)
      case action_name
      when 'change_status' then change_status(params)
      when 'transfer_team' then transfer_team(params)
      when 'add_label' then add_label(params)
      when 'assign_responsible' then assign_responsible(params)
      end
    end

    def change_status(params)
      status = @ticket.account.ticket_statuses.find_by(id: params['ticket_status_id'])
      return unless status

      @ticket.update!(ticket_status: status)
    end

    # Mesma regra RN01 do transfer manual: troca de time pausa timers ativos
    # sem gerar worklog.
    def transfer_team(params)
      team = @ticket.account.teams.find_by(id: params['team_id'])
      return unless team

      @ticket.active_timers.destroy_all
      @ticket.update!(team: team, setor_atual: team.name)
    end

    def add_label(params)
      label = params['label']
      return if label.blank?

      @ticket.add_labels([label])
    end

    def assign_responsible(params)
      user = @ticket.account.users.find_by(id: params['responsavel_id'])
      return unless user

      @ticket.update!(responsavel: user)
    end
  end
end
