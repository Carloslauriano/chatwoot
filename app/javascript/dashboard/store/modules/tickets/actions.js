import {
  SET_TICKET_UI_FLAG,
  CLEAR_TICKETS,
  SET_TICKETS,
  SET_TICKET_ITEM,
  SET_LAST_KANBAN_PARAMS,
} from './types';
import TicketsAPI from '../../../api/tickets';

// Guarda contra respostas fora de ordem: o board recarrega a lista inteira a
// cada fetch (CLEAR_TICKETS + SET_TICKETS), então uma resposta lenta poderia
// sobrescrever um resultado mais recente (ex: trocar de filtro rapidamente).
let fetchByTeamsRequestId = 0;

// Debounce do refresh disparado por realtime (ticket.created/updated via
// ActionCable): evita um refetch por evento quando vários tickets mudam em
// sequência rápida (ex: importação em lote).
const REALTIME_REFRESH_DEBOUNCE_MS = 500;
let realtimeRefreshTimer = null;

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

  // Com filtro de time/busca/atribuído a mim: usado pela página "Kanban".
  fetchByTeams: async (
    { commit },
    { teamIds = [], q = '', assignedToMe = false } = {}
  ) => {
    fetchByTeamsRequestId += 1;
    const requestId = fetchByTeamsRequestId;
    // Guarda os filtros ativos pra permitir que o realtime (ticket.created/
    // updated) reconsulte o board com o mesmo filtro quando algo mudar.
    commit(SET_LAST_KANBAN_PARAMS, { teamIds, q, assignedToMe });
    commit(SET_TICKET_UI_FLAG, { isFetching: true });
    try {
      const { data } = await TicketsAPI.list({
        teamIds,
        q,
        assignedToMe,
      });
      if (requestId !== fetchByTeamsRequestId) return;
      commit(CLEAR_TICKETS);
      commit(SET_TICKETS, data);
    } catch (error) {
      if (requestId !== fetchByTeamsRequestId) return;
      throw new Error(error);
    } finally {
      if (requestId === fetchByTeamsRequestId) {
        commit(SET_TICKET_UI_FLAG, { isFetching: false });
      }
    }
  },

  // Chamado ao desmontar TicketsKanban.vue — sem isso, eventos de realtime
  // continuariam disparando refetches do board mesmo com o usuário em outra
  // tela.
  clearKanbanParams: ({ commit }) => {
    clearTimeout(realtimeRefreshTimer);
    commit(SET_LAST_KANBAN_PARAMS, null);
  },

  // Disparado pelo helper de ActionCable quando qualquer ticket da conta é
  // criado/atualizado. No-op se o Kanban não estiver montado (lastKanbanParams
  // null) ou se os filtros ativos não tiverem sido definidos ainda.
  refreshKanban: ({ dispatch, state }) => {
    if (!state.lastKanbanParams) return;

    clearTimeout(realtimeRefreshTimer);
    realtimeRefreshTimer = setTimeout(() => {
      if (state.lastKanbanParams) {
        dispatch('fetchByTeams', state.lastKanbanParams);
      }
    }, REALTIME_REFRESH_DEBOUNCE_MS);
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
