class CreateTicketStatusTeams < ActiveRecord::Migration[7.1]
  def change
    create_table :ticket_status_teams do |t|
      t.references :ticket_status, null: false, foreign_key: { on_delete: :cascade }
      t.references :team, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :ticket_status_teams, [:ticket_status_id, :team_id], unique: true, name: 'idx_ticket_status_teams_unique'
  end
end
