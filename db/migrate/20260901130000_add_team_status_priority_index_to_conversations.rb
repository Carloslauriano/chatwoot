class AddTeamStatusPriorityIndexToConversations < ActiveRecord::Migration[7.1]
  def change
    add_index :conversations, [:team_id, :status, :priority], name: 'index_conversations_on_team_status_priority'
  end
end
