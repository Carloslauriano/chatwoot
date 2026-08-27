import {
  SET_TICKET_UI_FLAG,
  CLEAR_TICKETS,
  SET_TICKETS,
  SET_TICKET_ITEM,
} from './types';
import TicketsAPI from '../../../api/tickets';

export const actions = {
  // Sem filtro de time: usado pela página "Tickets" (mostra todos).
  fetchAll: async ({ commit }) => {
    commit(SET_TICKET_UI_FLAG, { isFetching: true });
    try {
      const { data } = await TicketsAPI.list();
      commit(CLEAR_TICKETS);
      commit(SET_TICKETS, data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(SET_TICKET_UI_FLAG, { isFetching: false });
    }
  },

  // Com filtro de time: usado pela página "Kanban".
  fetchByTeams: async ({ commit }, teamIds = []) => {
    commit(SET_TICKET_UI_FLAG, { isFetching: true });
    try {
      const { data } = await TicketsAPI.list(teamIds);
      commit(CLEAR_TICKETS);
      commit(SET_TICKETS, data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(SET_TICKET_UI_FLAG, { isFetching: false });
    }
  },

  updateStatusMacro: async ({ commit }, { ticketId, statusMacro }) => {
    commit(SET_TICKET_UI_FLAG, { isUpdating: true });
    try {
      const { data } = await TicketsAPI.updateStatusMacro(
        ticketId,
        statusMacro
      );
      commit(SET_TICKET_ITEM, data);
      return data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(SET_TICKET_UI_FLAG, { isUpdating: false });
    }
  },

  // Substitui updateStatusMacro — usado pelo Kanban de colunas configuráveis.
  updateTicketStatus: async ({ commit }, { ticketId, ticketStatusId }) => {
    commit(SET_TICKET_UI_FLAG, { isUpdating: true });
    try {
      const { data } = await TicketsAPI.updateTicketStatus(
        ticketId,
        ticketStatusId
      );
      commit(SET_TICKET_ITEM, data);
      return data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(SET_TICKET_UI_FLAG, { isUpdating: false });
    }
  },

  archive: async ({ commit }, ticketId) => {
    commit(SET_TICKET_UI_FLAG, { isUpdating: true });
    try {
      const { data } = await TicketsAPI.archive(ticketId);
      commit(SET_TICKET_ITEM, data);
      return data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(SET_TICKET_UI_FLAG, { isUpdating: false });
    }
  },

  unarchive: async ({ commit }, ticketId) => {
    commit(SET_TICKET_UI_FLAG, { isUpdating: true });
    try {
      const { data } = await TicketsAPI.unarchive(ticketId);
      commit(SET_TICKET_ITEM, data);
      return data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(SET_TICKET_UI_FLAG, { isUpdating: false });
    }
  },
};
