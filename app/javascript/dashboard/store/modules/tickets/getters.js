export const getters = {
  getTickets($state) {
    return Object.values($state.records)
      .filter(ticket => !ticket.archived)
      .sort((a, b) => a.id - b.id);
  },
  getTicketsByStatusMacro: $state => statusMacro => {
    return Object.values($state.records)
      .filter(ticket => !ticket.archived && ticket.status_macro === statusMacro)
      .sort((a, b) => a.id - b.id);
  },
  getTicketsByTicketStatus: $state => ticketStatusId => {
    return Object.values($state.records)
      .filter(
        ticket => !ticket.archived && ticket.ticket_status_id === ticketStatusId
      )
      .sort((a, b) => a.id - b.id);
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
};
