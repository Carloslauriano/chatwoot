class CreateTicketMacros < ActiveRecord::Migration[7.1]
  def change
    create_table :ticket_macros do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false
      t.jsonb :actions, null: false, default: []
      t.bigint :created_by_id
      t.bigint :updated_by_id

      t.timestamps
    end
  end
end
