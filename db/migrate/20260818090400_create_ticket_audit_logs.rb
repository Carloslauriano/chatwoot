class CreateTicketAuditLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :ticket_audit_logs do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }
      t.references :ticket, null: false, foreign_key: { on_delete: :cascade }
      t.bigint :autor_id, null: false
      t.string :acao, null: false
      t.string :campo
      t.jsonb :valor_antes
      t.jsonb :valor_depois

      t.datetime :created_at, null: false
    end

    add_index :ticket_audit_logs, [:ticket_id, :created_at]
  end
end
