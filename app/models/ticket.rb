# == Schema Information
#
# Table name: tickets
#
#  id             :bigint           not null, primary key
#  categoria      :string           not null
#  descricao      :text             not null
#  titulo         :string           not null
#  prioridade     :integer          default("baixa"), not null
#  resolvido_em   :datetime
#  setor_atual    :string           default("suporte"), not null
#  status_macro   :integer          default("caixa_entrada"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :bigint           not null
#  contact_id     :bigint           not null
#  conversation_id :bigint          not null
#  responsavel_id :bigint           not null
#
class Ticket < ApplicationRecord
  include Labelable

  belongs_to :account
  belongs_to :conversation
  belongs_to :contact
  belongs_to :responsavel, class_name: 'User'
  belongs_to :team, optional: true
  belongs_to :ticket_status, optional: true

  has_many :ticket_assignments, dependent: :destroy
  has_many :ticket_timeline_events, dependent: :destroy
  has_many :worklogs, dependent: :destroy
  has_many :ticket_audit_logs, dependent: :destroy
  has_many :active_timers, dependent: :destroy

  enum prioridade: { baixa: 0, media: 1, alta: 2, critica: 3 }
  enum status_macro: { caixa_entrada: 0, a_fazer: 1, fazendo: 2, aguardando_versao: 3, resolvido: 4 }

  validates :descricao, presence: true
  validates :titulo, presence: true

  before_save :set_resolvido_em, if: :will_save_change_to_status_macro?

  # US09: tempo bruto = diferença entre abertura da conversa no Chatwoot e resolução do ticket
  def tempo_bruto_segundos
    fim = resolvido_em || Time.current
    (fim - conversation.created_at).to_i
  end

  # US09/G4-G5: tempo líquido = soma de worklogs (nunca inferido por status)
  def tempo_liquido_segundos
    worklogs.sum(:duracao_segundos)
  end

  private

  def set_resolvido_em
    self.resolvido_em = resolvido? ? Time.current : nil
  end
end
