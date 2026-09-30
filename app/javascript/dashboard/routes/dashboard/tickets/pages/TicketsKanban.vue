<script setup>
import { computed, onMounted, onUnmounted, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useToggle } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';
import { debounce } from '@chatwoot/utils';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import KanbanColumn from '../components/KanbanColumn.vue';
import TicketQuickViewModal from 'dashboard/components/widgets/conversation/tickets/TicketQuickViewModal.vue';
import CreateStandaloneTicket from 'dashboard/components/widgets/conversation/tickets/CreateStandaloneTicket.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import SelectMenu from 'dashboard/components-next/selectmenu/SelectMenu.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';

const DEBOUNCE_DELAY = 300;

const { t } = useI18n();
const store = useStore();
const route = useRoute();
const router = useRouter();

const myTeams = useMapGetter('teams/getMyTeams');
const teams = useMapGetter('teams/getTeams');
const ticketStatuses = useMapGetter('ticketStatuses/getTicketStatuses');
const agentsList = useMapGetter('agents/getActiveAgents');
const getTicketsByTicketStatus = useMapGetter(
  'tickets/getTicketsByTicketStatus'
);
const uiFlags = useMapGetter('tickets/getUIFlags');

const openTicketId = ref(null);
const showTicketModal = ref(false);
const showCreateTicketModal = ref(false);
// Preenchido quando o "+ Criar novo ticket" de uma coluna específica é
// clicado — null quando é o botão genérico do topo (sem status pré-definido).
const createFromColumn = ref(null);

// 'mine' | 'all' | '<teamId>' — só um id de time específico habilita a
// sobreposição de posição por time (não faz sentido com múltiplos times).
const teamFilter = ref('mine');
// 'priority' (padrão: prioridade maior primeiro, id menor como desempate) |
// 'newest' | 'oldest'.
const sortMode = ref('priority');
// Dimensões independentes do filtro de time: combinam via AND no backend.
const searchQuery = ref('');
const assignedToMeFilter = ref(false);

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

// Time "correspondente" de uma coluna, usado pelo "+ Criar novo ticket" de
// cada coluna: se um time específico está filtrado, ele já garante que só
// aparecem colunas compatíveis (ver visibleColumns), então vale sempre; sem
// filtro específico ('mine'/'all'), só dá pra afirmar um time sem ambiguidade
// se a coluna estiver vinculada a exatamente um.
const correspondingTeamId = column => {
  if (singleTeamId.value) return singleTeamId.value;
  if (column.team_ids && column.team_ids.length === 1)
    return column.team_ids[0];
  return null;
};

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
  store.dispatch('tickets/fetchByTeams', {
    teamIds: teamIdsFilter.value,
    q: searchQuery.value,
    assignedToMe: assignedToMeFilter.value,
  });
};

const onSearch = debounce(value => {
  searchQuery.value = value;
  fetchTickets();
}, DEBOUNCE_DELAY);

const handleMoved = ({ ticketId, ticketStatusId }) => {
  store.dispatch('tickets/updateTicketStatus', {
    ticketId,
    ticketStatusId,
  });
};

// Abrir/fechar o modal seta o estado local DIRETO (não depende do router
// resolver a navegação pra aparecer na tela) — a URL é só sincronizada em
// paralelo, best-effort, pra permitir link direto/reload e voltar/avançar no
// navegador. O watch abaixo só aplica a URL->estado quando ela muda por fora
// (mount com ?ticket= já presente, ou navegação voltar/avançar), nunca
// desfazendo uma abertura que acabou de ser feita localmente.
const openTicket = ticket => {
  openTicketId.value = ticket.id;
  showTicketModal.value = true;
  router.push({
    name: route.name,
    params: route.params,
    query: { ...route.query, ticket: ticket.id },
  });
};

const closeTicketModal = () => {
  showTicketModal.value = false;
  fetchTickets();
  if (route.query.ticket) {
    const { ticket: _ticket, ...rest } = route.query;
    router.replace({ name: route.name, params: route.params, query: rest });
  }
};

watch(
  () => route.query.ticket,
  value => {
    if (value && Number(value) !== openTicketId.value) {
      openTicketId.value = Number(value);
      showTicketModal.value = true;
    } else if (!value && showTicketModal.value) {
      showTicketModal.value = false;
    }
  },
  { immediate: true }
);

const openCreateTicketModal = (column = null) => {
  createFromColumn.value = column
    ? { ticketStatusId: column.id, teamId: correspondingTeamId(column) }
    : null;
  showCreateTicketModal.value = true;
};

const closeCreateTicketModal = () => {
  showCreateTicketModal.value = false;
};

const onTicketCreated = () => {
  showCreateTicketModal.value = false;
  fetchTickets();
};

watch(teamFilter, fetchTickets);
watch(assignedToMeFilter, fetchTickets);

onMounted(async () => {
  await store.dispatch('teams/get');
  await store.dispatch('ticketStatuses/get');
  if (!agentsList.value.length) {
    store.dispatch('agents/get');
  }
  fetchTickets();
});

// Sem isso, ticket.created/updated recebidos via ActionCable continuariam
// disparando refetch do board mesmo com o usuário fora do Kanban.
onUnmounted(() => {
  store.dispatch('tickets/clearKanbanParams');
});
</script>

<template>
  <div class="flex flex-col w-full h-full p-6 overflow-hidden">
    <div class="flex items-center justify-between flex-shrink-0 mb-4">
      <h1 class="text-xl font-medium text-n-slate-12">
        {{ t('SIDEBAR.TICKETS_KANBAN') }}
      </h1>
      <div class="relative flex items-center gap-2">
        <Input
          :model-value="searchQuery"
          type="search"
          :placeholder="t('TICKETS.KANBAN.FILTER.SEARCH_PLACEHOLDER')"
          :custom-input-class="[
            'h-8 [&:not(.focus)]:!border-transparent bg-n-alpha-2 dark:bg-n-solid-1 ltr:!pl-8 !py-1 rtl:!pr-8',
          ]"
          class="w-56"
          @input="onSearch($event.target.value)"
        >
          <template #prefix>
            <Icon
              icon="i-lucide-search"
              class="absolute -translate-y-1/2 text-n-slate-11 size-4 top-1/2 ltr:left-2 rtl:right-2"
            />
          </template>
        </Input>
        <Icon
          v-if="uiFlags.isFetching"
          icon="i-lucide-loader-circle"
          class="animate-spin text-n-slate-11 size-4"
        />
        <Button
          icon="i-lucide-plus"
          :label="t('TICKETS.KANBAN.NEW_TICKET')"
          xs
          @click="openCreateTicketModal()"
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
          <div class="flex items-center justify-between gap-2 mt-4">
            <span class="text-sm truncate text-n-slate-12">
              {{ t('TICKETS.KANBAN.FILTER.ASSIGNED_TO_ME') }}
            </span>
            <Switch v-model="assignedToMeFilter" />
          </div>
        </div>
      </div>
    </div>

    <div class="flex flex-1 min-h-0 gap-4 overflow-x-auto">
      <KanbanColumn
        v-for="column in visibleColumns"
        :key="column.id"
        :title="column.name"
        :ticket-status-id="column.id"
        :tickets="ticketsForColumn(column.id)"
        @moved="handleMoved"
        @open="openTicket"
        @create="openCreateTicketModal(column)"
      />
    </div>

    <woot-modal
      v-model:show="showTicketModal"
      :on-close="closeTicketModal"
      size="medium"
      class="!items-start [&>div]:!top-12 [&>div]:sticky [&>div]:!max-h-[calc(100vh-6rem)]"
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
            :default-team-id="
              createFromColumn ? createFromColumn.teamId : singleTeamId
            "
            :default-ticket-status-id="createFromColumn?.ticketStatusId"
            @close="closeCreateTicketModal"
            @created="onTicketCreated"
          />
        </div>
      </div>
    </woot-modal>
  </div>
</template>
