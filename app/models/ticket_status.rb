# Coluna do Kanban configurável pelo usuário (substitui o enum status_macro
# como fonte de verdade). Pode ser vinculada a um ou mais times — usado para
# filtrar quais colunas aparecem no Kanban por time.
class TicketStatus < ApplicationRecord
  belongs_to :account

  has_many :ticket_status_teams, dependent: :destroy
  has_many :teams, through: :ticket_status_teams
  has_many :tickets, dependent: :nullify

  validates :name, presence: true

  default_scope { order(:position) }

  before_save :unset_other_defaults, if: :is_default?

  private

  # Só um status padrão por conta — usado pelo TicketsController#create
  # quando o ticket não chega com um ticket_status_id explícito.
  def unset_other_defaults
    account.ticket_statuses.where.not(id: id).update_all(is_default: false)
  end
end
