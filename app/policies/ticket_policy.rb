# G7: qualquer colaborador do setor (agent ou administrator) pode criar,
# transferir e avançar o status macro — sem restrição extra de papel.
class TicketPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    true
  end

  def update?
    true
  end

  def destroy?
    true
  end

  def link_conversation?
    true
  end

  def transfer?
    true
  end

  def ticket_status?
    true
  end

  def timer_start?
    true
  end

  def timer_stop?
    true
  end

  def timeline?
    true
  end

  def audit_logs?
    true
  end
end
