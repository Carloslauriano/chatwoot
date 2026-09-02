# == Schema Information
#
# Table name: worklogs
#
#  id                   :bigint           not null, primary key
#  duracao_segundos     :integer          not null
#  editado_manualmente  :boolean          default(FALSE), not null
#  fim                  :datetime         not null
#  inicio               :datetime         not null
#  motivo               :string
#  origem               :integer          default("timer"), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  account_id           :bigint           not null
#  colaborador_id       :bigint           not null
#  ticket_id            :bigint           not null
#
class Worklog < ApplicationRecord
  belongs_to :account
  belongs_to :ticket
  belongs_to :colaborador, class_name: 'User'

  enum origem: { timer: 0, manual: 1 }

  before_validation :derive_fim_from_duration

  validates :inicio, :fim, :duracao_segundos, presence: true

  private

  def derive_fim_from_duration
    return if fim.present?
    return if inicio.blank? || duracao_segundos.blank?

    self.fim = inicio + duracao_segundos.seconds
  end
end
