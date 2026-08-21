import {
  SET_TICKET_UI_FLAG,
  CLEAR_TICKETS,
  SET_TICKETS,
  SET_TICKET_ITEM,
} from './types';

export const mutations = {
  [SET_TICKET_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },

  [CLEAR_TICKETS]: $state => {
    $state.records = {};
  },

  [SET_TICKETS]: ($state, data) => {
    const updatedRecords = { ...$state.records };
    data.forEach(ticket => {
      updatedRecords[ticket.id] = {
        ...(updatedRecords[ticket.id] || {}),
        ...ticket,
      };
    });
    $state.records = updatedRecords;
  },

  [SET_TICKET_ITEM]: ($state, data) => {
    $state.records = {
      ...$state.records,
      [data.id]: {
        ...($state.records[data.id] || {}),
        ...data,
      },
    };
  },
};
