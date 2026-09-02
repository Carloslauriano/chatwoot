<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import KanbanColumn from '../components/KanbanColumn.vue';
import TicketQuickViewModal from 'dashboard/components/widgets/conversation/tickets/TicketQuickViewModal.vue';
import CreateStandaloneTicket from 'dashboard/components/widgets/conversation/tickets/CreateStandaloneTicket.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import SelectMenu from 'dashboard/components-next/selectmenu/SelectMenu.vue';

const { t } = useI18n();
const store = useStore();

const myTeams = useMapGetter('teams/getMyTeams');
const teams = useMapGetter('teams/getTeams');
const ticketStatuses = useMapGetter('ticketStatuses/getTicketStatuses');
const getTicketsByTicketStatus = useMapGetter(
  'tickets/getTicketsByTicketStatus'
);

const openTicketId = ref(null);
const showTicketModal = ref(false);
const showCreateTicketModal = ref(false);

// 'mine' | 'all' | '<teamId>' — só um id de time específico habilita a
// sobreposição de posição por time (não faz sentido com múltiplos times).
const teamFilter = ref('mine');
// 'priority' (padrão: prioridade maior primeiro, id menor como desempate) |
// 'newest' | 'oldest'.
const sortMode = ref('priority');

const [showFilterPanel, toggleFilterPanel] = useToggle();

const teamFilterOptions = computed(() => [
  { label: t('TICKETS.KANBAN.FILTER.MINE'), value: 'mine' },
  { label: t('TICKETS.KANBAN.FILTER.ALL'), value: 'all' },
  ...teams.value.map(team => ({ label: team.name, value: String(team.id) })),
]);

const sortOptions = computed(() => [
  { label: t('TICKETS.KANBAN.SORT.PRIORITY'), value: 'priority' },
  { label: t('TICKETS.KANBAN.SORT.NEWEST'), value: 'newest' },
  { label: t('TICKETS.KANBAN.SORT.OLDEST'), value: 'oldest' },
]);

const activeTeamFilterLabel = computed(
  () =>
    teamFilterOptions.value.find(option => option.value === teamFilter.value)
      ?.label || ''
);
const activeSortLabel = computed(
  () =>
    sortOptions.value.find(option => option.value === sortMode.value)?.label ||
    ''
);

const singleTeamId = computed(() =>
  ['mine', 'all'].includes(teamFilter.value) ? null : Number(teamFilter.value)
);

const teamIdsFilter = computed(() => {
  if (teamFilter.value === 'mine') return myTeams.value.map(team => team.id);
  if (teamFilter.value === 'all') return [];
  return [singleTeamId.value];
});

// Posição da coluna: se um time específico está filtrado e a coluna tem uma
// posição definida pra aquele time, ela sobrepõe a posição global.
const columnPosition = column => {
  if (singleTeamId.value) {
    const override = (column.team_positions || []).find(
      teamPosition => teamPosition.team_id === singleTeamId.value
    );
    if (override) return override.position;
  }
  return column.position || 0;
};

// Coluna sem time vinculado aparece sempre; com time, só se bater com o filtro.
const visibleColumns = computed(() => {
  const allowedTeamIds = teamIdsFilter.value;
  const columns =
    teamFilter.value === 'all'
      ? ticketStatuses.value
      : ticketStatuses.value.filter(column => {
          if (!column.team_ids || !column.team_ids.length) return true;
          return column.team_ids.some(id => allowedTeamIds.includes(id));
        });
  return [...columns].sort((a, b) => columnPosition(a) - columnPosition(b));
});

// Padrão do Kanban: prioridade maior primeiro, id menor (mais antigo) acima
// como desempate dentro da mesma prioridade.
const PRIORITY_RANK = { critica: 3, alta: 2, media: 1, baixa: 0 };
const sortTickets = tickets => {
  const sorted = [...tickets];
  if (sortMode.value === 'newest') return sorted.sort((a, b) => b.id - a.id);
  if (sortMode.value === 'oldest') return sorted.sort((a, b) => a.id - b.id);
  return sorted.sort(
    (a, b) =>
      (PRIORITY_RANK[b.prioridade] ?? -1) -
        (PRIORITY_RANK[a.prioridade] ?? -1) || a.id - b.id
  );
};

const ticketsForColumn = columnId =>
  sortTickets(getTicketsByTicketStatus.value(columnId));

const fetchTickets = () => {
  store.dispatch('tickets/fetchByTeams', teamIdsFilter.value);
};

const handleMoved = ({ ticketId, ticketStatusId }) => {
  store.dispatch('tickets/updateTicketStatus', {
    ticketId,
    ticketStatusId,
  });
};

const openTicket = ticket => {
  openTicketId.value = ticket.id;
  showTicketModal.value = true;
};

const closeTicketModal = () => {
  showTicketModal.value = false;
  fetchTickets();
};

const closeCreateTicketModal = () => {
  showCreateTicketModal.value = false;
};

const onTicketCreated = () => {
  showCreateTicketModal.value = false;
  fetchTickets();
};

watch(teamFilter, fetchTickets);

onMounted(async () => {
  await store.dispatch('teams/get');
  await store.dispatch('ticketStatuses/get');
  fetchTickets();
});
</script>

<template>
  <div class="flex flex-col w-full h-full p-6 overflow-hidden">
    <div class="flex items-center justify-between mb-4">
      <h1 class="text-xl font-medium text-n-slate-12">
        {{ t('SIDEBAR.TICKETS_KANBAN') }}
      </h1>
      <div class="relative flex gap-2">
        <Button
          icon="i-lucide-plus"
          :label="t('TICKETS.KANBAN.NEW_TICKET')"
          xs
          @click="showCreateTicketModal = true"
        />
        <Button
          v-tooltip.left="t('TICKETS.KANBAN.FILTER.TOOLTIP')"
          icon="i-lucide-list-filter"
          slate
          faded
          xs
          @click="toggleFilterPanel()"
        />
        <div
          v-if="showFilterPanel"
          v-on-click-outside="() => toggleFilterPanel()"
          class="absolute right-0 z-40 p-4 mt-1 border rounded-xl shadow-lg top-full w-72 bg-n-alpha-3 backdrop-blur-[100px] border-n-weak"
        >
          <div class="flex items-center justify-between gap-2">
            <span class="text-sm truncate text-n-slate-12">
              {{ t('TICKETS.KANBAN.FILTER.TEAM_LABEL') }}
            </span>
            <SelectMenu
              :model-value="teamFilter"
              :options="teamFilterOptions"
              :label="activeTeamFilterLabel"
              sub-menu-position="left"
              @update:model-value="value => (teamFilter = value)"
            />
          </div>
          <div class="flex items-center justify-between gap-2 mt-4">
            <span class="text-sm truncate text-n-slate-12">
              {{ t('TICKETS.KANBAN.FILTER.SORT_LABEL') }}
            </span>
            <SelectMenu
              :model-value="sortMode"
              :options="sortOptions"
              :label="activeSortLabel"
              sub-menu-position="left"
              @update:model-value="value => (sortMode = value)"
            />
          </div>
        </div>
      </div>
    </div>

    <div class="flex flex-1 gap-4 overflow-x-auto">
      <KanbanColumn
        v-for="column in visibleColumns"
        :key="column.id"
        :title="column.name"
        :ticket-status-id="column.id"
        :tickets="ticketsForColumn(column.id)"
        @moved="handleMoved"
        @open="openTicket"
      />
    </div>

    <woot-modal
      v-model:show="showTicketModal"
      :on-close="closeTicketModal"
      size="medium"
      class="!items-start [&>div]:!top-12 [&>div]:sticky"
    >
      <TicketQuickViewModal
        v-if="openTicketId"
        :ticket-id="openTicketId"
        @close="closeTicketModal"
        @updated="fetchTickets"
      />
    </woot-modal>

    <woot-modal
      v-model:show="showCreateTicketModal"
      :on-close="closeCreateTicketModal"
      size="medium"
    >
      <div class="flex flex-col h-auto overflow-auto">
        <woot-modal-header
          :header-title="t('TICKETS.KANBAN.CREATE_MODAL.TITLE')"
        />
        <div class="flex flex-col px-8 pb-4">
          <CreateStandaloneTicket
            @close="closeCreateTicketModal"
            @created="onTicketCreated"
          />
        </div>
      </div>
    </woot-modal>
  </div>
</template>
