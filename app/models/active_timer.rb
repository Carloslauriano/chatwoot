# == Schema Information
#
# Table name: active_timers
#
#  id             :bigint           not null, primary key
#  iniciado_em    :datetime         not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :bigint           not null
#  colaborador_id :bigint           not null
#  ticket_id      :bigint           not null
#
# RN01: um colaborador só pode ter 1 timer ativo por vez — garantido pela
# constraint UNIQUE(colaborador_id) no banco, refletida aqui na validação.
class ActiveTimer < ApplicationRecord
  belongs_to :account
  belongs_to :ticket
  belongs_to :colaborador, class_name: 'User'

  validates :colaborador_id, uniqueness: true
end
