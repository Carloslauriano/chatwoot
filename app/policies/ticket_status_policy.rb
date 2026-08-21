# Mesma regra do TicketPolicy — qualquer account_user (agent/administrator)
# pode gerenciar as colunas do Kanban.
class TicketStatusPolicy < ApplicationPolicy
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
end
