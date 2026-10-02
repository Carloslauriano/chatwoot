class Tickets::TimelineNotificationService
  pattr_initialize [:ticket_timeline_event!]

  def perform
    recipients.each do |recipient|
      next if already_notified?(recipient)

      NotificationBuilder.new(
        notification_type: 'ticket_activity',
        user: recipient,
        account: account,
        primary_actor: ticket,
        secondary_actor: ticket_timeline_event
      ).perform
    end
  end

  private

  delegate :ticket, :account, to: :ticket_timeline_event

  def recipients
    ([ticket.responsavel] + ticket.ticket_assignments.map(&:colaborador)).compact.uniq - [actor]
  end

  def actor
    return nil if ticket_timeline_event.autor_id.blank?

    User.find_by(id: ticket_timeline_event.autor_id)
  end

  def already_notified?(user)
    ticket.notifications.exists?(user: user, secondary_actor: ticket_timeline_event)
  end
end
