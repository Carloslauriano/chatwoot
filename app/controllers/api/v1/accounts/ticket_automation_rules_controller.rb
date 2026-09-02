# CRUD de automações de tickets — só admin (mesma regra do AutomationRule nativo).
class Api::V1::Accounts::TicketAutomationRulesController < Api::V1::Accounts::BaseController
  before_action :fetch_ticket_automation_rule, only: [:update, :destroy]
  before_action :check_authorization

  def index
    @ticket_automation_rules = Current.account.ticket_automation_rules
  end

  def create
    @ticket_automation_rule = Current.account.ticket_automation_rules.new(ticket_automation_rule_params)
    @ticket_automation_rule.save!
  end

  def update
    @ticket_automation_rule.update!(ticket_automation_rule_params)
  end

  def destroy
    @ticket_automation_rule.destroy!
    head :no_content
  end

  private

  def fetch_ticket_automation_rule
    @ticket_automation_rule = Current.account.ticket_automation_rules.find(params[:id])
  end

  def ticket_automation_rule_params
    params.require(:ticket_automation_rule).permit(
      :name, :description, :event_name, :active,
      conditions: [:to_ticket_status_id, :to_team_id, :team_id, :label, :ticket_status_id],
      actions: [:action_name, :ticket_status_id, :team_id, :label, :responsavel_id]
    )
  end
end
