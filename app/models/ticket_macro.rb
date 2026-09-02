# Ação em lote sobre um Ticket (status, time, labels, prioridade, arquivamento),
# disparada manualmente pelo usuário — ver TicketMacros::RunnerService.
# Mesmo padrão estrutural do Macro nativo (actions jsonb + validação de
# ACTIONS_ATTRS), mas escopado para o domínio Ticket, não Conversation.
class TicketMacro < ApplicationRecord
  belongs_to :account
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true

  validates :name, presence: true
  validate :json_actions_format

  ACTIONS_ATTRS = %w[change_ticket_status assign_team add_label remove_label change_priority archive_ticket
                     unarchive_ticket].freeze

  private

  def json_actions_format
    return if actions.blank?

    attributes = actions.map { |obj| obj['action_name'] }
    invalid = attributes - ACTIONS_ATTRS

    errors.add(:actions, "Ticket macro execution actions #{invalid.join(',')} not supported.") if invalid.any?
  end
end
