class AddTeamIdToTickets < ActiveRecord::Migration[7.1]
  def up
    add_reference :tickets, :team, null: true, foreign_key: { on_delete: :nullify }
    add_index :tickets, [:account_id, :team_id]

    # Best-effort backfill: liga tickets existentes a um Team com o mesmo nome
    # de setor_atual (case-insensitive), quando existir na mesma conta.
    execute <<~SQL.squish
      UPDATE tickets
      SET team_id = teams.id
      FROM teams
      WHERE teams.account_id = tickets.account_id
        AND lower(teams.name) = lower(tickets.setor_atual)
        AND tickets.team_id IS NULL
    SQL
  end

  def down
    remove_index :tickets, [:account_id, :team_id]
    remove_reference :tickets, :team, foreign_key: { on_delete: :nullify }
  end
end
