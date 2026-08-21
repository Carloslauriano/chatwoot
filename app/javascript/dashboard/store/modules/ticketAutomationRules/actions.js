import {
  SET_TICKET_AUTOMATION_RULE_UI_FLAG,
  SET_TICKET_AUTOMATION_RULES,
  ADD_TICKET_AUTOMATION_RULE,
  EDIT_TICKET_AUTOMATION_RULE,
  DELETE_TICKET_AUTOMATION_RULE,
} from './types';
import TicketAutomationRulesAPI from '../../../api/ticketAutomationRules';

export const actions = {
  get: async ({ commit }) => {
    commit(SET_TICKET_AUTOMATION_RULE_UI_FLAG, { isFetching: true });
    try {
      const { data } = await TicketAutomationRulesAPI.get();
      commit(SET_TICKET_AUTOMATION_RULES, data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(SET_TICKET_AUTOMATION_RULE_UI_FLAG, { isFetching: false });
    }
  },

  create: async ({ commit }, ticketAutomationRule) => {
    commit(SET_TICKET_AUTOMATION_RULE_UI_FLAG, { isCreating: true });
    try {
      const { data } = await TicketAutomationRulesAPI.create({
        ticket_automation_rule: ticketAutomationRule,
      });
      commit(ADD_TICKET_AUTOMATION_RULE, data);
      return data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(SET_TICKET_AUTOMATION_RULE_UI_FLAG, { isCreating: false });
    }
  },

  update: async ({ commit }, { id, ...ticketAutomationRule }) => {
    commit(SET_TICKET_AUTOMATION_RULE_UI_FLAG, { isUpdating: true });
    try {
      const { data } = await TicketAutomationRulesAPI.update(id, {
        ticket_automation_rule: ticketAutomationRule,
      });
      commit(EDIT_TICKET_AUTOMATION_RULE, data);
      return data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(SET_TICKET_AUTOMATION_RULE_UI_FLAG, { isUpdating: false });
    }
  },

  delete: async ({ commit }, id) => {
    commit(SET_TICKET_AUTOMATION_RULE_UI_FLAG, { isDeleting: true });
    try {
      await TicketAutomationRulesAPI.delete(id);
      commit(DELETE_TICKET_AUTOMATION_RULE, id);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(SET_TICKET_AUTOMATION_RULE_UI_FLAG, { isDeleting: false });
    }
  },
};
