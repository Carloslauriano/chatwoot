// Helpers compartilhados entre os componentes de ticket (Kanban card, header,
// popup) para não duplicar mapeamento de cor/ícone e cálculo de iniciais.

export const PRIORITY_COLOR = {
  baixa: 'slate',
  media: 'blue',
  alta: 'amber',
  critica: 'ruby',
};

// Ícones já existentes na coleção nativa do Chatwoot (usados no seletor de
// prioridade da conversa) — reaproveitados aqui em vez de criar novos.
export const PRIORITY_ICON = {
  baixa: 'i-woot-priority-low',
  media: 'i-woot-priority-medium',
  alta: 'i-woot-priority-high',
  critica: 'i-woot-priority-urgent',
};

// Label.vue só aceita 6 cores fixas (classes estáticas do Tailwind) — como as
// etiquetas de ticket são nomes livres (acts_as_taggable_on, sem cor definida
// pelo usuário), escolhemos uma de forma determinística pelo nome, pra cada
// etiqueta sempre ter a mesma cor sem precisar de classe dinâmica.
const LABEL_COLOR_CYCLE = ['amber', 'teal', 'ruby', 'blue', 'iris', 'slate'];
export const colorForLabel = name => {
  let hash = 0;
  for (let i = 0; i < name.length; i += 1) {
    hash = hash * 31 + name.charCodeAt(i);
  }
  return LABEL_COLOR_CYCLE[Math.abs(hash) % LABEL_COLOR_CYCLE.length];
};

// Avatar com foto real (com fallback pra iniciais coloridas) fica a cargo do
// componente nativo `dashboard/components-next/avatar/Avatar.vue` — sem
// helper de cor/iniciais próprio aqui.
