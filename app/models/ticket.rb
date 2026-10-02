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
#  contact_id     :bigint
#  conversation_id :bigint
#  responsavel_id :bigint           not null
#
class Ticket < ApplicationRecord
  include Labelable

  NUMERO_MAXIMO_ANEXOS = 15

  belongs_to :account
  belongs_to :conversation, optional: true
  belongs_to :contact, optional: true
  belongs_to :responsavel, class_name: 'User'
  belongs_to :team, optional: true
  belongs_to :ticket_status, optional: true

  has_many :ticket_assignments, dependent: :destroy
  has_many :ticket_timeline_events, dependent: :destroy
  has_many :worklogs, dependent: :destroy
  has_many :ticket_audit_logs, dependent: :destroy
  has_many :active_timers, dependent: :destroy
  has_many :notifications, as: :primary_actor, dependent: :destroy_async
  has_many_attached :anexos

  enum prioridade: { baixa: 0, media: 1, alta: 2, critica: 3 }
  enum status_macro: { caixa_entrada: 0, a_fazer: 1, fazendo: 2, aguardando_versao: 3, resolvido: 4 }

  validates :descricao, presence: true
  validates :titulo, presence: true
  validate :anexos_validos

  before_save :set_resolvido_em, if: :will_save_change_to_status_macro?
  before_save :enrich_descricao_links, if: :will_save_change_to_descricao?
  after_create_commit :dispatch_created_event
  after_update_commit :dispatch_updated_event

  # US09: tempo bruto = diferença entre abertura da conversa no Chatwoot e resolução do ticket
  def tempo_bruto_segundos
    fim = resolvido_em || Time.current
    inicio_referencia = conversation&.created_at || created_at
    (fim - inicio_referencia).to_i
  end

  # US09/G4-G5: tempo líquido = soma de worklogs (nunca inferido por status)
  def tempo_liquido_segundos
    worklogs.sum(:duracao_segundos)
  end

  def push_event_data
    {
      id: id,
      titulo: titulo,
      status_macro: status_macro,
      conversation_id: conversation_id,
      responsavel_id: responsavel_id,
      account_id: account_id
    }
  end

  private

  # Board kanban ouve esses dois eventos (via ActionCable) pra atualizar em
  # tempo real sem depender de refetch manual do usuário.
  def dispatch_created_event
    Rails.configuration.dispatcher.dispatch(TICKET_CREATED, Time.zone.now, ticket: self)
  end

  def dispatch_updated_event
    Rails.configuration.dispatcher.dispatch(TICKET_UPDATED, Time.zone.now, ticket: self)
  end

  def set_resolvido_em
    self.resolvido_em = resolvido? ? Time.current : nil
  end

  def enrich_descricao_links
    self.descricao = LinkTextEnricherService.enrich(descricao)
  end

  def anexos_validos
    return unless anexos.attached?

    errors.add(:anexos, 'quantidade máxima de anexos excedida') if anexos.size > NUMERO_MAXIMO_ANEXOS

    anexos.each do |anexo|
      validar_tamanho_anexo(anexo.blob)
      validar_tipo_anexo(anexo.blob)
    end
  end

  def validar_tamanho_anexo(blob)
    limite_mb = GlobalConfigService.load('MAXIMUM_FILE_UPLOAD_SIZE', 40).to_i
    limite_mb = 40 if limite_mb <= 0

    errors.add(:anexos, "#{blob.filename} excede o tamanho máximo permitido") if blob.byte_size > limite_mb.megabytes
  end

  def validar_tipo_anexo(blob)
    tipo = blob.content_type.to_s
    aceito = tipo.start_with?('image/', 'video/', 'audio/') || Attachment::ACCEPTABLE_FILE_TYPES.include?(tipo)

    errors.add(:anexos, "tipo de arquivo #{tipo} não suportado") unless aceito
  end
end
