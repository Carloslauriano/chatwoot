/* global axios */

import ApiClient from './ApiClient';

class TicketAttachmentsAPI extends ApiClient {
  constructor() {
    super('tickets', { accountScoped: true });
  }

  create(ticketId, files) {
    const formData = new FormData();
    files.forEach(file => formData.append('anexos[]', file));
    return axios.post(`${this.url}/${ticketId}/attachments`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
  }

  destroy(ticketId, attachmentId) {
    return axios.delete(`${this.url}/${ticketId}/attachments/${attachmentId}`);
  }
}

export default new TicketAttachmentsAPI();
