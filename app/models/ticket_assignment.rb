# == Schema Information
#
# Table name: ticket_assignments
#
#  id              :bigint           not null, primary key
#  status_micro    :integer          default("a_fazer"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  colaborador_id  :bigint           not null
#  ticket_id       :bigint           not null
#
class TicketAssignment < ApplicationRecord
  belongs_to :account
  belongs_to :ticket
  belongs_to :colaborador, class_name: 'User'

  enum status_micro: { a_fazer: 0, fazendo: 1, finalizado: 2 }

  validates :colaborador_id, uniqueness: { scope: :ticket_id }
end
