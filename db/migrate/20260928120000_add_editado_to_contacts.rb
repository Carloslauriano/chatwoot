class AddEditadoToContacts < ActiveRecord::Migration[7.1]
  def change
    add_column :contacts, :editado, :boolean, default: false, null: false
  end
end
