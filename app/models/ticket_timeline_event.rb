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
  NUMERO_MAXIMO_ANEXOS = 15

  belongs_to :account
  belongs_to :ticket

  has_many_attached :anexos

  enum tipo_evento: {
    mensagem_cliente: 0,
    nota_interna: 1,
    status_macro_changed: 2,
    status_micro_changed: 3,
    setor_changed: 4,
    worklog: 5,
    worklog_manual: 6,
    membro_added: 7,
    membro_removed: 8,
    comentario: 9
  }
  enum origem: { chatwoot: 0, interno: 1, sistema: 2 }

  validate :anexos_permitidos_apenas_em_comentario
  validate :anexos_validos

  before_save :enrich_texto_links, if: -> { comentario? && payload['texto'].present? && will_save_change_to_payload? }

  private

  def enrich_texto_links
    self.payload = payload.merge('texto' => LinkTextEnricherService.enrich(payload['texto']))
  end

  def anexos_permitidos_apenas_em_comentario
    errors.add(:anexos, 'só são permitidos em eventos do tipo comentário') if anexos.attached? && !comentario?
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
