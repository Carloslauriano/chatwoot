class Api::V1::Accounts::Tickets::LabelsController < Api::V1::Accounts::BaseController
  include LabelConcern

  before_action :ticket

  # Sobrescreve o create do LabelConcern (que só faz update_labels + expõe
  # @labels) pra também disparar TicketAutomationRules pras etiquetas novas.
  def create
    labels_before = ticket.label_list
    model.update_labels(permitted_params[:labels])
    @labels = ticket.label_list

    (@labels - labels_before).each do |label|
      TicketAutomationRules::RunnerService.new(
        ticket, event_name: 'ticket_label_added', label: label
      ).perform
    end
  end

  private

  def ticket
    @ticket ||= Current.account.tickets.find(params[:ticket_id])
  end

  def model
    @model ||= @ticket
  end

  def permitted_params
    params.permit(:ticket_id, labels: [])
  end
end
