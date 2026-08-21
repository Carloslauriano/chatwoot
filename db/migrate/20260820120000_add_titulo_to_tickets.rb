class AddTituloToTickets < ActiveRecord::Migration[7.1]
  def up
    add_column :tickets, :titulo, :string

    Ticket.find_each do |ticket|
      ticket.update_column(:titulo, ticket.descricao.to_s.lines.first.to_s.strip.truncate(80))
    end

    change_column_null :tickets, :titulo, false
  end

  def down
    remove_column :tickets, :titulo
  end
end
