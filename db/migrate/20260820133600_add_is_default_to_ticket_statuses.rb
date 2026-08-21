class AddIsDefaultToTicketStatuses < ActiveRecord::Migration[7.1]
  def change
    add_column :ticket_statuses, :is_default, :boolean, default: false, null: false
  end
end
