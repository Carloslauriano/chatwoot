import { getters } from './getters';
import { actions } from './actions';
import { mutations } from './mutations';

const state = {
  records: {},
  uiFlags: {
    isFetching: false,
    isUpdating: false,
  },
  // Últimos filtros usados pelo Kanban (null quando a página não está
  // montada) — permite que o handler de realtime do ActionCable saiba se/como
  // reconsultar a lista quando qualquer ticket da conta é criado/atualizado.
  lastKanbanParams: null,
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
