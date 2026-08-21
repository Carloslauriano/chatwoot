class CreateActiveTimers < ActiveRecord::Migration[7.1]
  def change
    create_table :active_timers do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }
      # RN01: um colaborador só pode ter 1 timer ativo por vez — garantido por constraint de banco.
      t.references :colaborador, null: false, foreign_key: { to_table: :users, on_delete: :cascade }, index: { unique: true }
      t.references :ticket, null: false, foreign_key: { on_delete: :cascade }
      t.datetime :iniciado_em, null: false

      t.timestamps
    end
  end
end
