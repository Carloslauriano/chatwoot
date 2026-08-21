import {
  SET_TICKET_STATUS_UI_FLAG,
  SET_TICKET_STATUSES,
  ADD_TICKET_STATUS,
  EDIT_TICKET_STATUS,
  DELETE_TICKET_STATUS,
} from './types';
import TicketStatusesAPI from '../../../api/ticketStatuses';

export const actions = {
  get: async ({ commit }) => {
    commit(SET_TICKET_STATUS_UI_FLAG, { isFetching: true });
    try {
      const { data } = await TicketStatusesAPI.get();
      commit(SET_TICKET_STATUSES, data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(SET_TICKET_STATUS_UI_FLAG, { isFetching: false });
    }
  },

  create: async ({ commit }, ticketStatus) => {
    commit(SET_TICKET_STATUS_UI_FLAG, { isCreating: true });
    try {
      const { data } = await TicketStatusesAPI.create({
        ticket_status: ticketStatus,
      });
      commit(ADD_TICKET_STATUS, data);
      return data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(SET_TICKET_STATUS_UI_FLAG, { isCreating: false });
    }
  },

  update: async ({ commit }, { id, ...ticketStatus }) => {
    commit(SET_TICKET_STATUS_UI_FLAG, { isUpdating: true });
    try {
      const { data } = await TicketStatusesAPI.update(id, {
        ticket_status: ticketStatus,
      });
      commit(EDIT_TICKET_STATUS, data);
      return data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(SET_TICKET_STATUS_UI_FLAG, { isUpdating: false });
    }
  },

  delete: async ({ commit }, id) => {
    commit(SET_TICKET_STATUS_UI_FLAG, { isDeleting: true });
    try {
      await TicketStatusesAPI.delete(id);
      commit(DELETE_TICKET_STATUS, id);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(SET_TICKET_STATUS_UI_FLAG, { isDeleting: false });
    }
  },
};
