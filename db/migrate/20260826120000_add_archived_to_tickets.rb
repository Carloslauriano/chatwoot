class AddArchivedToTickets < ActiveRecord::Migration[7.1]
  def change
    add_column :tickets, :archived, :boolean, null: false, default: false
    add_index :tickets, [:account_id, :archived]
  end
end
