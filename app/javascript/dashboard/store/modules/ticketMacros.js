import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import TicketMacrosAPI from '../../api/ticketMacros';
import { throwErrorMessage } from '../utils/api';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
    isExecuting: false,
  },
};

export const getters = {
  getTicketMacros($state) {
    return $state.records;
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
};

export const actions = {
  get: async function getTicketMacros({ commit }) {
    commit(types.SET_TICKET_MACROS_UI_FLAG, { isFetching: true });
    try {
      const response = await TicketMacrosAPI.get();
      commit(types.SET_TICKET_MACROS, response.data.payload);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_TICKET_MACROS_UI_FLAG, { isFetching: false });
    }
  },
  create: async function createTicketMacro({ commit }, ticketMacroObj) {
    commit(types.SET_TICKET_MACROS_UI_FLAG, { isCreating: true });
    try {
      const response = await TicketMacrosAPI.create({
        ticket_macro: ticketMacroObj,
      });
      commit(types.ADD_TICKET_MACRO, response.data.payload);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_TICKET_MACROS_UI_FLAG, { isCreating: false });
    }
  },
  update: async ({ commit }, { id, ...updateObj }) => {
    commit(types.SET_TICKET_MACROS_UI_FLAG, { isUpdating: true });
    try {
      const response = await TicketMacrosAPI.update(id, {
        ticket_macro: updateObj,
      });
      commit(types.EDIT_TICKET_MACRO, response.data.payload);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_TICKET_MACROS_UI_FLAG, { isUpdating: false });
    }
  },
  delete: async ({ commit }, id) => {
    commit(types.SET_TICKET_MACROS_UI_FLAG, { isDeleting: true });
    try {
      await TicketMacrosAPI.delete(id);
      commit(types.DELETE_TICKET_MACRO, id);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_TICKET_MACROS_UI_FLAG, { isDeleting: false });
    }
  },
  execute: async ({ commit }, { id, ticketId }) => {
    commit(types.SET_TICKET_MACROS_UI_FLAG, { isExecuting: true });
    try {
      await TicketMacrosAPI.execute(id, ticketId);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_TICKET_MACROS_UI_FLAG, { isExecuting: false });
    }
  },
};

export const mutations = {
  [types.SET_TICKET_MACROS_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },
  [types.SET_TICKET_MACROS]: MutationHelpers.set,
  [types.ADD_TICKET_MACRO]: MutationHelpers.setSingleRecord,
  [types.EDIT_TICKET_MACRO]: MutationHelpers.update,
  [types.DELETE_TICKET_MACRO]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  actions,
  state,
  getters,
  mutations,
};
