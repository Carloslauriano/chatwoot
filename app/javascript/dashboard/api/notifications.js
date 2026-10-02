/* global axios */
import ApiClient from './ApiClient';

class NotificationsAPI extends ApiClient {
  constructor() {
    super('notifications', { accountScoped: true });
  }

  get({ page, status, type, sortOrder, notificationType }) {
    const includesFilter = [status, type].filter(value => !!value);

    return axios.get(this.url, {
      params: {
        page,
        sort_order: sortOrder,
        includes: includesFilter,
        notification_type: notificationType,
      },
    });
  }

  getNotifications(contactId) {
    return axios.get(`${this.url}/${contactId}/notifications`);
  }

  getUnreadCount(params = {}) {
    return axios.get(`${this.url}/unread_count`, { params });
  }

  read(primaryActorType, primaryActorId) {
    return axios.post(`${this.url}/read_all`, {
      primary_actor_type: primaryActorType,
      primary_actor_id: primaryActorId,
    });
  }

  unRead(id) {
    return axios.post(`${this.url}/${id}/unread`);
  }

  readAll() {
    return axios.post(`${this.url}/read_all`);
  }

  delete(id) {
    return axios.delete(`${this.url}/${id}`);
  }

  deleteAll({ type = 'all' }) {
    return axios.post(`${this.url}/destroy_all`, {
      type,
    });
  }

  snooze({ id, snoozedUntil = null }) {
    return axios.post(`${this.url}/${id}/snooze`, {
      snoozed_until: snoozedUntil,
    });
  }
}

export default new NotificationsAPI();
