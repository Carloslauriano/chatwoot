class CreateTicketTimelineEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :ticket_timeline_events do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }
      t.references :ticket, null: false, foreign_key: { on_delete: :cascade }
      t.integer :tipo_evento, null: false
      t.integer :origem, null: false
      t.bigint :autor_id
      t.jsonb :payload, null: false, default: {}

      t.datetime :created_at, null: false
    end

    add_index :ticket_timeline_events, [:ticket_id, :created_at]
  end
end
