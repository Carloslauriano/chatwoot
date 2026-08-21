class AddDefaultForTicketsToTeams < ActiveRecord::Migration[7.1]
  def change
    add_column :teams, :default_for_tickets, :boolean, default: false, null: false
  end
end
