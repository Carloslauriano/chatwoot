# == Schema Information
#
# Table name: ticket_timeline_events
#
#  id          :bigint           not null, primary key
#  origem      :integer          not null
#  payload     :jsonb            not null
#  tipo_evento :integer          not null
#  created_at  :datetime         not null
#  account_id  :bigint           not null
#  autor_id    :bigint
#  ticket_id   :bigint           not null
#
class TicketTimelineEvent < ApplicationRecord
  belongs_to :account
  belongs_to :ticket

  enum tipo_evento: {
    mensagem_cliente: 0,
    nota_interna: 1,
    status_macro_changed: 2,
    status_micro_changed: 3,
    setor_changed: 4,
    worklog: 5,
    worklog_manual: 6,
    membro_added: 7,
    membro_removed: 8
  }
  enum origem: { chatwoot: 0, interno: 1, sistema: 2 }
end
