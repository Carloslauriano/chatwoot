import ApiClient from './ApiClient';

class TicketAutomationRulesAPI extends ApiClient {
  constructor() {
    super('ticket_automation_rules', { accountScoped: true });
  }
}

export default new TicketAutomationRulesAPI();
