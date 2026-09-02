# Mesma regra do TicketStatusPolicy — qualquer account_user (agent/administrator)
# pode gerenciar e executar macros de ticket.
class TicketMacroPolicy < ApplicationPolicy
  def index?
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

  def execute?
    true
  end
end
