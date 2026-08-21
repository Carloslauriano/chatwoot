class AddTicketStatusIdToTickets < ActiveRecord::Migration[7.1]
  STATUS_MACRO_SEED = [
    ['Caixa de Entrada', 0],
    ['A Fazer', 1],
    ['Fazendo', 2],
    ['Aguardando Versão', 3],
    ['Resolvido', 4],
  ].freeze

  def up
    add_reference :tickets, :ticket_status, null: true, foreign_key: { on_delete: :nullify }

    # Backfill: cria as 5 colunas padrão por conta (mesmos nomes do enum
    # legado status_macro) e liga os tickets existentes a elas. status_macro
    # NÃO é removido — fica como legado não usado.
    #
    # INSERT via SQL puro (não TicketStatus.create!): o model tem um
    # before_save que chama is_default?, coluna que só existe a partir da
    # migração 20260820133600 — instanciar o model aqui quebra numa base
    # nova, migrando tudo em sequência a partir do zero.
    Account.find_each do |account|
      status_by_macro_value = STATUS_MACRO_SEED.map do |name, position|
        result = execute(<<~SQL.squish)
          INSERT INTO ticket_statuses (account_id, name, position, created_at, updated_at)
          VALUES (#{account.id}, #{connection.quote(name)}, #{position}, NOW(), NOW())
          RETURNING id
        SQL
        [position, result.first['id']]
      end.to_h

      status_by_macro_value.each do |status_macro_value, ticket_status_id|
        execute <<~SQL.squish
          UPDATE tickets
          SET ticket_status_id = #{ticket_status_id}
          WHERE account_id = #{account.id}
            AND status_macro = #{status_macro_value}
            AND ticket_status_id IS NULL
        SQL
      end
    end
  end

  def down
    remove_reference :tickets, :ticket_status, foreign_key: { on_delete: :nullify }
  end
end
