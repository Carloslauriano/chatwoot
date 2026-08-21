class CreateTicketStatuses < ActiveRecord::Migration[7.1]
  def change
    create_table :ticket_statuses do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.string :color, null: false, default: '#1f93ff'

      t.timestamps
    end

    add_index :ticket_statuses, [:account_id, :position]
  end
end
