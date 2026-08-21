class CreateTicketAssignments < ActiveRecord::Migration[7.1]
  def change
    create_table :ticket_assignments do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }
      t.references :ticket, null: false, foreign_key: { on_delete: :cascade }
      t.references :colaborador, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.integer :status_micro, null: false, default: 0

      t.timestamps
    end

    add_index :ticket_assignments, [:ticket_id, :colaborador_id], unique: true, name: 'uniq_ticket_id_colaborador_id'
  end
end
