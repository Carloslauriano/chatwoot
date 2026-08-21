<script setup>
import { computed, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAgentsList } from 'dashboard/composables/useAgentsList';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import TicketsAPI from 'dashboard/api/tickets';
import MultiselectDropdown from 'shared/components/ui/MultiselectDropdown.vue';
import AddLabel from 'shared/components/ui/dropdown/AddLabel.vue';
import LabelDropdown from 'shared/components/ui/label/LabelDropdown.vue';
import Label from 'dashboard/components-next/label/Label.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import {
  PRIORITY_COLOR,
  PRIORITY_ICON,
  colorForLabel,
} from 'dashboard/helper/ticketCardHelper';
import TimerWidget from './TimerWidget.vue';
import ManualTimeEntryModal from './ManualTimeEntryModal.vue';

const props = defineProps({
  ticket: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['updated']);
const { t } = useI18n();
const store = useStore();
const { formatMessage } = useMessageFormatter();

const currentUser = useMapGetter('getCurrentUser');
const teams = useMapGetter('teams/getTeams');
const ticketStatuses = useMapGetter('ticketStatuses/getTicketStatuses');
const { agentsList } = useAgentsList(false);
const accountLabels = useMapGetter('labels/getLabels');

const ticket = computed(() => props.ticket);

const myAssignment = computed(() =>
  (ticket.value.assignments || []).find(
    assignment => assignment.colaborador_id === currentUser.value.id
  )
);

const myActiveTimer = computed(() =>
  (ticket.value.active_timers || []).find(
    timer => timer.colaborador_id === currentUser.value.id
  )
);

const statusMicroOptions = ['a_fazer', 'fazendo', 'finalizado'].map(key => ({
  id: key,
  name: t(`TICKETS.STATUS_MICRO_OPTIONS.${key.toUpperCase()}`),
}));

const teamOptions = computed(() => [
  { id: null, name: t('TICKETS.CREATE.TEAM.NONE') },
  ...(teams.value || []),
]);

const selectedTeam = computed(
  () => teamOptions.value.find(team => team.id === ticket.value.team_id) || {}
);

const selectedStatus = computed(
  () =>
    ticketStatuses.value.find(
      status => status.id === ticket.value.ticket_status_id
    ) || {}
);

const onSelectTeam = async item => {
  try {
    await TicketsAPI.transferTeam(ticket.value.id, item.id || null);
    useAlert(t('TICKETS.HEADER.TRANSFER_SUCCESS'));
    emit('updated');
  } catch (error) {
    useAlert(t('TICKETS.HEADER.TRANSFER_ERROR'));
  }
};

const onSelectStatus = async item => {
  try {
    await store.dispatch('tickets/updateTicketStatus', {
      ticketId: ticket.value.id,
      ticketStatusId: item.id,
    });
    emit('updated');
  } catch (error) {
    useAlert(t('TICKETS.HEADER.STATUS_MACRO_UPDATE_ERROR'));
  }
};

const onSelectResponsible = async item => {
  try {
    await TicketsAPI.update(ticket.value.id, {
      ticket: { responsavel_id: item.id },
    });
    useAlert(t('TICKETS.HEADER.RESPONSIBLE_UPDATE_SUCCESS'));
    emit('updated');
  } catch (error) {
    useAlert(t('TICKETS.HEADER.RESPONSIBLE_UPDATE_ERROR'));
  }
};

// Membros — avatar clicável (estilo Trello: círculo com foto, ou pontilhado
// com "+" quando não há responsável) abre um painel simples com a lista de
// agentes, em vez do MultiselectDropdown padrão (largo/pesado demais aqui).
const showResponsibleDropdown = ref(false);
const closeResponsibleDropdown = () => {
  showResponsibleDropdown.value = false;
};
const selectResponsibleAgent = async agent => {
  showResponsibleDropdown.value = false;
  await onSelectResponsible(agent);
};

const onChangeStatusMicro = async event => {
  const value = event.target.value;
  if (!myAssignment.value) return;
  try {
    await TicketsAPI.updateStatusMicro(
      ticket.value.id,
      myAssignment.value.id,
      value
    );
    emit('updated');
  } catch (error) {
    useAlert(t('TICKETS.HEADER.STATUS_MICRO_UPDATE_ERROR'));
  }
};

// Etiquetas — mesmo componente de seletor usado nas conversas (AddLabel +
// LabelDropdown), em vez de uma grade de botões própria.
const isTogglingLabels = ref(false);
const showLabelDropdown = ref(false);
const closeLabelDropdown = () => {
  showLabelDropdown.value = false;
};

const toggleLabel = async title => {
  if (isTogglingLabels.value) return;
  const current = ticket.value.label_list || [];
  const next = current.includes(title)
    ? current.filter(label => label !== title)
    : [...current, title];

  try {
    isTogglingLabels.value = true;
    await TicketsAPI.updateLabels(ticket.value.id, next);
    emit('updated');
  } catch (error) {
    useAlert(t('TICKETS.HEADER.LABELS_UPDATE_ERROR'));
  } finally {
    isTogglingLabels.value = false;
  }
};

// Título — editável inline, mostrado como "#id — título" no topo do card.
const isEditingTitle = ref(false);
const titleDraft = ref('');
const isSavingTitle = ref(false);

const startEditingTitle = () => {
  titleDraft.value = ticket.value.titulo;
  isEditingTitle.value = true;
};

const cancelEditingTitle = () => {
  isEditingTitle.value = false;
};

const saveTitle = async () => {
  if (!titleDraft.value.trim()) return;
  try {
    isSavingTitle.value = true;
    await TicketsAPI.update(ticket.value.id, {
      ticket: { titulo: titleDraft.value.trim() },
    });
    isEditingTitle.value = false;
    emit('updated');
  } catch (error) {
    useAlert(t('TICKETS.HEADER.TITLE_UPDATE_ERROR'));
  } finally {
    isSavingTitle.value = false;
  }
};

// Descrição — editável inline com o editor de markdown completo (mesmo
// ProseMirror do composer de mensagens), como no card do Trello.
const isEditingDescription = ref(false);
const descriptionDraft = ref('');
const isSavingDescription = ref(false);

const startEditingDescription = () => {
  descriptionDraft.value = ticket.value.descricao;
  isEditingDescription.value = true;
};

const cancelEditingDescription = () => {
  isEditingDescription.value = false;
};

const saveDescription = async () => {
  if (!descriptionDraft.value.trim()) return;
  try {
    isSavingDescription.value = true;
    await TicketsAPI.update(ticket.value.id, {
      ticket: { descricao: descriptionDraft.value.trim() },
    });
    isEditingDescription.value = false;
    emit('updated');
  } catch (error) {
    useAlert(t('TICKETS.HEADER.DESCRIPTION_UPDATE_ERROR'));
  } finally {
    isSavingDescription.value = false;
  }
};

const onWorklogCreated = () => emit('updated');

const showManualTimeModal = ref(false);
const openManualTimeModal = () => {
  showManualTimeModal.value = true;
};
const onManualTimeSaved = () => {
  showManualTimeModal.value = false;
  emit('updated');
};

onMounted(() => {
  if (!ticketStatuses.value.length) {
    store.dispatch('ticketStatuses/get');
  }
  if (!accountLabels.value?.length) {
    store.dispatch('labels/get');
  }
});
</script>

<template>
  <div class="flex flex-col gap-3 p-3 border rounded-xl border-n-weak">
    <!-- #id — título -->
    <div class="flex items-start justify-between gap-2">
      <div class="flex-1 min-w-0">
        <div v-if="!isEditingTitle" class="flex items-center gap-2">
          <h2 class="text-base font-semibold truncate text-n-slate-12">
            #{{ ticket.id }} — {{ ticket.titulo }}
          </h2>
          <button
            type="button"
            class="text-xs shrink-0 text-n-slate-11 hover:underline"
            @click="startEditingTitle"
          >
            {{ t('TICKETS.HEADER.EDIT') }}
          </button>
        </div>
        <div v-else class="flex flex-col gap-2">
          <input
            v-model="titleDraft"
            type="text"
            class="text-sm rounded-xl border border-n-weak"
          />
          <div class="flex items-center gap-2">
            <Button
              faded
              slate
              size="small"
              :label="t('TICKETS.CREATE.CANCEL')"
              @click="cancelEditingTitle"
            />
            <Button
              size="small"
              :label="t('TICKETS.HEADER.SAVE')"
              :is-loading="isSavingTitle"
              @click="saveTitle"
            />
          </div>
        </div>
      </div>
      <Label
        class="shrink-0"
        :label="ticket.prioridade"
        :color="PRIORITY_COLOR[ticket.prioridade] || 'slate'"
        compact
      >
        <template #icon>
          <span
            :class="PRIORITY_ICON[ticket.prioridade]"
            class="text-current size-3"
          />
        </template>
      </Label>
    </div>

    <!-- Status / Time -->
    <div class="flex flex-col gap-1">
      <span class="text-xs text-n-slate-11">
        {{ t('TICKETS.HEADER.STATUS_MACRO') }}
      </span>
      <MultiselectDropdown
        class="w-full"
        :options="ticketStatuses"
        :selected-item="selectedStatus"
        :multiselector-placeholder="t('TICKETS.HEADER.STATUS_MACRO')"
        :input-placeholder="t('TICKETS.HEADER.STATUS_MACRO')"
        :has-thumbnail="false"
        @select="onSelectStatus"
      />
    </div>

    <div class="flex flex-col gap-1">
      <span class="text-xs text-n-slate-11">
        {{ t('TICKETS.HEADER.TEAM') }}
      </span>
      <MultiselectDropdown
        class="w-full"
        :options="teamOptions"
        :selected-item="selectedTeam"
        :multiselector-placeholder="t('TICKETS.CREATE.TEAM.PLACEHOLDER')"
        :input-placeholder="t('TICKETS.CREATE.TEAM.PLACEHOLDER')"
        :has-thumbnail="false"
        @select="onSelectTeam"
      />
    </div>

    <label
      v-if="myAssignment"
      class="flex items-center gap-2 text-xs text-n-slate-11"
    >
      {{ t('TICKETS.HEADER.MY_STATUS') }}
      <select
        class="text-xs rounded-lg border border-n-weak"
        :value="myAssignment.status_micro"
        @change="onChangeStatusMicro"
      >
        <option
          v-for="option in statusMicroOptions"
          :key="option.id"
          :value="option.id"
        >
          {{ option.name }}
        </option>
      </select>
    </label>

    <!-- Membros -->
    <div class="flex flex-col gap-1">
      <span class="text-xs font-medium text-n-slate-11">
        {{ t('TICKETS.HEADER.MEMBERS') }}
      </span>
      <div v-on-clickaway="closeResponsibleDropdown" class="relative w-fit">
        <button
          type="button"
          class="block"
          @click="showResponsibleDropdown = !showResponsibleDropdown"
        >
          <Avatar
            v-if="ticket.responsavel_nome"
            v-tooltip="ticket.responsavel_nome"
            :src="ticket.responsavel_avatar_url"
            :name="ticket.responsavel_nome"
            :size="28"
            rounded-full
          />
          <span
            v-else
            class="flex items-center justify-center w-7 h-7 border border-dashed rounded-full text-n-slate-10 border-n-slate-6 hover:border-n-slate-8 hover:text-n-slate-11"
          >
            <span class="text-sm i-lucide-plus" />
          </span>
        </button>
        <div
          v-show="showResponsibleDropdown"
          class="absolute z-[100] w-56 p-1 mt-1 overflow-y-auto border rounded-lg shadow-lg top-full max-h-60 bg-n-alpha-3 backdrop-blur-[100px] border-n-strong"
        >
          <button
            v-for="agent in agentsList"
            :key="agent.id"
            type="button"
            class="flex items-center w-full gap-2 px-2 py-1.5 text-sm text-left rounded-md hover:bg-n-alpha-1"
            :class="{ 'bg-n-alpha-1': agent.id === ticket.responsavel_id }"
            @click="selectResponsibleAgent(agent)"
          >
            <Avatar
              :src="agent.thumbnail"
              :name="agent.name"
              :size="20"
              rounded-full
            />
            <span class="truncate text-n-slate-12">{{ agent.name }}</span>
          </button>
        </div>
      </div>
    </div>

    <!-- Etiquetas -->
    <div class="flex flex-col gap-1">
      <span class="text-xs font-medium text-n-slate-11">
        {{ t('TICKETS.HEADER.LABELS') }}
      </span>
      <div
        v-on-clickaway="closeLabelDropdown"
        class="relative flex flex-wrap items-center gap-1"
      >
        <AddLabel @add="showLabelDropdown = !showLabelDropdown" />
        <Label
          v-for="labelName in ticket.label_list"
          :key="labelName"
          :label="labelName"
          :color="colorForLabel(labelName)"
          compact
        />
        <div
          v-show="showLabelDropdown"
          class="absolute z-[100] w-72 p-2 mt-1 border rounded-lg shadow-lg top-full bg-n-alpha-3 backdrop-blur-[100px] border-n-strong"
        >
          <LabelDropdown
            v-if="showLabelDropdown"
            :account-labels="accountLabels"
            :selected-labels="ticket.label_list || []"
            :allow-creation="false"
            @add="label => toggleLabel(label.title)"
            @remove="toggleLabel"
          />
        </div>
      </div>
    </div>

    <!-- Categoria -->
    <span v-if="ticket.categoria" class="text-xs text-n-slate-11">
      {{ t('TICKETS.HEADER.CATEGORY') }}: {{ ticket.categoria }}
    </span>

    <!-- Descrição -->
    <div class="flex flex-col gap-1">
      <div class="flex items-center justify-between">
        <span class="text-xs font-medium text-n-slate-11">
          {{ t('TICKETS.HEADER.DESCRIPTION') }}
        </span>
        <button
          v-if="!isEditingDescription"
          type="button"
          class="text-xs text-n-slate-11 hover:underline"
          @click="startEditingDescription"
        >
          {{ t('TICKETS.HEADER.EDIT') }}
        </button>
      </div>
      <div
        v-if="!isEditingDescription"
        v-dompurify-html="formatMessage(ticket.descricao)"
        class="text-sm text-n-slate-12"
      />
      <div v-else class="flex flex-col gap-2">
        <WootMessageEditor
          v-model="descriptionDraft"
          channel-type="Context::Default"
          :enable-canned-responses="false"
        />
        <div class="flex items-center justify-end gap-2">
          <Button
            faded
            slate
            size="small"
            :label="t('TICKETS.CREATE.CANCEL')"
            @click="cancelEditingDescription"
          />
          <Button
            size="small"
            :label="t('TICKETS.HEADER.SAVE')"
            :is-loading="isSavingDescription"
            @click="saveDescription"
          />
        </div>
      </div>
    </div>

    <div v-if="myAssignment" class="flex items-center justify-between">
      <TimerWidget
        :ticket-id="ticket.id"
        :initial-state="myActiveTimer ? 'running' : 'stopped'"
        :initial-started-at="myActiveTimer?.iniciado_em"
        @worklog-created="onWorklogCreated"
      />
      <button
        type="button"
        class="text-xs text-n-slate-11 hover:underline"
        @click="openManualTimeModal"
      >
        {{ t('TICKETS.TIMER.ADD_TIME') }}
      </button>
    </div>

    <woot-modal
      v-model:show="showManualTimeModal"
      :on-close="() => (showManualTimeModal = false)"
    >
      <ManualTimeEntryModal
        :ticket-id="ticket.id"
        :worklog="null"
        @close="showManualTimeModal = false"
        @saved="onManualTimeSaved"
      />
    </woot-modal>
  </div>
</template>
