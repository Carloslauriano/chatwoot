class AutoAssignmentOnReplyListener < BaseListener
  include Events::Types

  def message_created(event)
    message, account = extract_message_and_account(event)
    return unless should_auto_assign?(message, account, event)

    conversation = message.conversation
    conversation.with_lock { conversation.update!(assignee: message.sender) }
  end

  private

  def should_auto_assign?(message, account, event)
    message.outgoing? &&
      !message.private? &&
      message.sender.is_a?(User) &&
      event.data[:originated_from_ui] &&
      account.auto_assign_on_agent_reply &&
      message.conversation.assignee_id.blank?
  end
end
