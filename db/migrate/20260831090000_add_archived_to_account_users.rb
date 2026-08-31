class AddArchivedToAccountUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :account_users, :archived, :boolean, null: false, default: false
    add_index :account_users, [:account_id, :archived]
  end
end
