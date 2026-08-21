# frozen_string_literal: true

FactoryBot.define do
  factory :ticket do
    titulo { 'Nota fiscal não emite' }
    descricao { 'Cliente não consegue emitir nota fiscal' }
    categoria { 'bug' }
    prioridade { :media }
    setor_atual { 'suporte' }
    status_macro { :caixa_entrada }

    after(:build) do |ticket|
      ticket.account ||= create(:account)
      ticket.conversation ||= create(:conversation, account: ticket.account)
      ticket.contact ||= ticket.conversation.contact
      ticket.responsavel ||= create(:user, account: ticket.account)
    end
  end

  factory :ticket_assignment do
    status_micro { :a_fazer }

    after(:build) do |assignment|
      assignment.account ||= assignment.ticket&.account || create(:account)
      assignment.ticket ||= create(:ticket, account: assignment.account)
      assignment.colaborador ||= create(:user, account: assignment.account)
    end
  end

  factory :worklog do
    inicio { 1.hour.ago }
    fim { Time.current }
    duracao_segundos { 3600 }
    origem { :timer }

    after(:build) do |worklog|
      worklog.account ||= worklog.ticket&.account || create(:account)
      worklog.ticket ||= create(:ticket, account: worklog.account)
      worklog.colaborador ||= create(:user, account: worklog.account)
    end
  end

  factory :active_timer do
    iniciado_em { Time.current }

    after(:build) do |active_timer|
      active_timer.account ||= active_timer.ticket&.account || create(:account)
      active_timer.ticket ||= create(:ticket, account: active_timer.account)
      active_timer.colaborador ||= create(:user, account: active_timer.account)
    end
  end

  factory :ticket_audit_log do
    acao { 'ticket_created' }

    after(:build) do |log|
      log.account ||= log.ticket&.account || create(:account)
      log.ticket ||= create(:ticket, account: log.account)
      log.autor_id ||= create(:user, account: log.account).id
    end
  end

  factory :ticket_timeline_event do
    tipo_evento { :nota_interna }
    origem { :interno }
    payload { {} }

    after(:build) do |event|
      event.account ||= event.ticket&.account || create(:account)
      event.ticket ||= create(:ticket, account: event.account)
    end
  end
end
