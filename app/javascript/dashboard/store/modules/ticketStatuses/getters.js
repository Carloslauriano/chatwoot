export const getters = {
  getTicketStatuses($state) {
    return Object.values($state.records).sort(
      (a, b) => (a.position || 0) - (b.position || 0)
    );
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
};
