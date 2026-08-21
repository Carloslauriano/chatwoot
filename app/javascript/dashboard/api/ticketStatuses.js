import ApiClient from './ApiClient';

class TicketStatusesAPI extends ApiClient {
  constructor() {
    super('ticket_statuses', { accountScoped: true });
  }
}

export default new TicketStatusesAPI();
