class AddPositionToTicketStatusTeams < ActiveRecord::Migration[7.1]
  def change
    add_column :ticket_status_teams, :position, :integer, default: 0, null: false
  end
end
