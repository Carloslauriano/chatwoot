class MakeTicketConversationAndContactOptional < ActiveRecord::Migration[7.1]
  def change
    change_column_null :tickets, :conversation_id, true
    change_column_null :tickets, :contact_id, true
  end
end
