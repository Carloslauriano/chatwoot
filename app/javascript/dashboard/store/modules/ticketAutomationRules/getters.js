export const getters = {
  getTicketAutomationRules($state) {
    return Object.values($state.records).sort((a, b) => a.id - b.id);
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
};
