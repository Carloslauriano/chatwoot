class CreateWorklogs < ActiveRecord::Migration[7.1]
  def change
    create_table :worklogs do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }
      t.references :ticket, null: false, foreign_key: { on_delete: :cascade }
      t.references :colaborador, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.datetime :inicio, null: false
      t.datetime :fim, null: false
      t.integer :duracao_segundos, null: false
      t.integer :origem, null: false, default: 0
      t.boolean :editado_manualmente, null: false, default: false
      t.string :motivo

      t.timestamps
    end
  end
end
