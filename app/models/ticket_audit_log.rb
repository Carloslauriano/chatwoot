# == Schema Information
#
# Table name: ticket_audit_logs
#
#  id           :bigint           not null, primary key
#  acao         :string           not null
#  campo        :string
#  valor_antes  :jsonb
#  valor_depois :jsonb
#  created_at   :datetime         not null
#  account_id   :bigint           not null
#  autor_id     :bigint           not null
#  ticket_id    :bigint           not null
#
class TicketAuditLog < ApplicationRecord
  belongs_to :account
  belongs_to :ticket

  validates :acao, presence: true
  validates :autor_id, presence: true
end
