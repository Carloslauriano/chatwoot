class CreateTicketAutomationRules < ActiveRecord::Migration[7.1]
  def change
    create_table :ticket_automation_rules do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false
      t.string :description
      t.string :event_name, null: false
      t.boolean :active, null: false, default: true
      t.jsonb :conditions, null: false, default: {}
      t.jsonb :actions, null: false, default: []

      t.timestamps
    end

    add_index :ticket_automation_rules, [:account_id, :event_name]
  end
end
