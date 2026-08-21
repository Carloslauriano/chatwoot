class CreateTickets < ActiveRecord::Migration[7.1]
  def change
    create_tickets
    add_ticket_indexes
  end

  private

  def create_tickets
    create_table :tickets do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }
      t.references :conversation, null: false, foreign_key: { on_delete: :cascade }
      t.references :contact, null: false, foreign_key: { on_delete: :cascade }
      t.references :responsavel, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.text :descricao, null: false
      t.string :categoria, null: false
      t.integer :prioridade, null: false, default: 0
      t.string :setor_atual, null: false, default: 'suporte'
      t.integer :status_macro, null: false, default: 0
      t.datetime :resolvido_em

      t.timestamps
    end
  end

  def add_ticket_indexes
    add_index :tickets, [:account_id, :conversation_id]
    add_index :tickets, [:account_id, :status_macro]
    add_index :tickets, [:account_id, :setor_atual]
  end
end
