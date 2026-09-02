# Automação escopada para tickets — dispara em 2 eventos (status mudou,
# etiqueta adicionada) e roda uma lista de ações (mudar status, transferir
# time, adicionar etiqueta, atribuir responsável). Não é um motor genérico
# como o AutomationRule nativo (sem operadores/atributos configuráveis) —
# escopo fechado no que foi pedido; ver TicketAutomationRules::RunnerService.
class TicketAutomationRule < ApplicationRecord
  EVENTS = %w[ticket_status_changed ticket_label_added ticket_team_changed].freeze
  ACTION_NAMES = %w[change_status transfer_team add_label assign_responsible].freeze

  belongs_to :account

  validates :name, presence: true
  validates :event_name, presence: true, inclusion: { in: EVENTS }

  default_scope { order(:created_at) }
end
