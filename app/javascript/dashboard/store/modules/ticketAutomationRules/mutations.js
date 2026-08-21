import {
  SET_TICKET_AUTOMATION_RULE_UI_FLAG,
  SET_TICKET_AUTOMATION_RULES,
  ADD_TICKET_AUTOMATION_RULE,
  EDIT_TICKET_AUTOMATION_RULE,
  DELETE_TICKET_AUTOMATION_RULE,
} from './types';

export const mutations = {
  [SET_TICKET_AUTOMATION_RULE_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },

  [SET_TICKET_AUTOMATION_RULES]: ($state, data) => {
    const updatedRecords = {};
    data.forEach(rule => {
      updatedRecords[rule.id] = rule;
    });
    $state.records = updatedRecords;
  },

  [ADD_TICKET_AUTOMATION_RULE]: ($state, data) => {
    $state.records = { ...$state.records, [data.id]: data };
  },

  [EDIT_TICKET_AUTOMATION_RULE]: ($state, data) => {
    $state.records = { ...$state.records, [data.id]: data };
  },

  [DELETE_TICKET_AUTOMATION_RULE]: ($state, id) => {
    const updatedRecords = { ...$state.records };
    delete updatedRecords[id];
    $state.records = updatedRecords;
  },
};
