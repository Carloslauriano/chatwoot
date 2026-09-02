/* global axios */

import ApiClient from './ApiClient';

class TicketMacrosAPI extends ApiClient {
  constructor() {
    super('ticket_macros', { accountScoped: true });
  }

  execute(id, ticketId) {
    return axios.post(`${this.url}/${id}/execute`, { ticket_id: ticketId });
  }
}

export default new TicketMacrosAPI();
