import {
  SET_TICKET_STATUS_UI_FLAG,
  SET_TICKET_STATUSES,
  ADD_TICKET_STATUS,
  EDIT_TICKET_STATUS,
  DELETE_TICKET_STATUS,
} from './types';

export const mutations = {
  [SET_TICKET_STATUS_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },

  [SET_TICKET_STATUSES]: ($state, data) => {
    const updatedRecords = {};
    data.forEach(ticketStatus => {
      updatedRecords[ticketStatus.id] = ticketStatus;
    });
    $state.records = updatedRecords;
  },

  [ADD_TICKET_STATUS]: ($state, data) => {
    $state.records = { ...$state.records, [data.id]: data };
  },

  [EDIT_TICKET_STATUS]: ($state, data) => {
    $state.records = { ...$state.records, [data.id]: data };
  },

  [DELETE_TICKET_STATUS]: ($state, id) => {
    const updatedRecords = { ...$state.records };
    delete updatedRecords[id];
    $state.records = updatedRecords;
  },
};
