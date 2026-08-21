class TicketStatusTeam < ApplicationRecord
  belongs_to :ticket_status
  belongs_to :team
end
