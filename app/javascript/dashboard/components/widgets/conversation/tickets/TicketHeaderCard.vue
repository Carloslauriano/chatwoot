<script setup>
import { computed, onMounted, ref } from 'vue';
import { format } from 'date-fns';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { formatDuration } from 'shared/helpers/timeHelper';
import TicketsAPI from 'dashboard/api/tickets';
import MultiselectDropdown from 'shared/components/ui/MultiselectDropdown.vue';
import AddLabel from 'shared/components/ui/dropdown/AddLabel.vue';
import LabelDropdown from 'shared/components/ui/label/LabelDropdown.vue';
import Label from 'dashboard/components-next/label/Label.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import AccordionItem from 'dashboard/components/Accordion/AccordionItem.vue';
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
const { isAdmin } = useAdmin();
const teams = useMapGetter('teams/getTeams');
const ticketStatuses = useMapGetter('ticketStatuses/getTicketStatuses');
// Agentes da conta inteira, não os assignable do inbox da conversa aberta —
// o card do ticket também é usado fora do contexto de uma conversa (Kanban,
// TicketShow), onde não há inbox_id para o useAgentsList filtrar por.
const agentsList = useMapGetter('agents/getAgents');
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

// Membros — bloco único (estilo Trello: avatares em fileira + "+" para
// adicionar) que reúne o responsável (marcado com estrela) e os demais
// colaboradores (ticket_assignments). Trocar o responsável = clicar na
// estrela de outro membro; para isso ele precisa já estar na lista.
const agentFor = colaboradorId =>
  agentsList.value.find(agent => agent.id === colaboradorId);

const members = computed(() => {
  const assignments = ticket.value.assignments || [];
  const responsavelId = ticket.value.responsavel_id;
  const responsavelAssignment = assignments.find(
    assignment => assignment.colaborador_id === responsavelId
  );

  const responsavelMember = responsavelId
    ? {
        key: `responsavel-${responsavelId}`,
        colaboradorId: responsavelId,
        nome: ticket.value.responsavel_nome,
        avatarUrl: ticket.value.responsavel_avatar_url,
        assignmentId: responsavelAssignment?.id || null,
        isResponsible: true,
      }
    : null;

  const otherMembers = assignments
    .filter(assignment => assignment.colaborador_id !== responsavelId)
    .map(assignment => ({
      key: `assignment-${assignment.id}`,
      colaboradorId: assignment.colaborador_id,
      nome: assignment.colaborador_nome,
      avatarUrl: agentFor(assignment.colaborador_id)?.thumbnail,
      assignmentId: assignment.id,
      isResponsible: false,
    }));

  return responsavelMember
    ? [responsavelMember, ...otherMembers]
    : otherMembers;
});

const showAddMemberDropdown = ref(false);
const closeAddMemberDropdown = () => {
  showAddMemberDropdown.value = false;
};
const memberOptions = computed(() => {
  const memberIds = members.value.map(member => member.colaboradorId);
  return agentsList.value.filter(agent => !memberIds.includes(agent.id));
});

const addMember = async agent => {
  showAddMemberDropdown.value = false;
  try {
    await TicketsAPI.addMember(ticket.value.id, agent.id);
    emit('updated');
  } catch (error) {
    useAlert(t('TICKETS.HEADER.MEMBER_ADD_ERROR'));
  }
};

const removeMember = async member => {
  if (!member.assignmentId) return;
  try {
    await TicketsAPI.removeMember(ticket.value.id, member.assignmentId);
    emit('updated');
  } catch (error) {
    useAlert(t('TICKETS.HEADER.MEMBER_REMOVE_ERROR'));
  }
};

const promoteToResponsible = async member => {
  if (member.isResponsible) return;
  try {
    await TicketsAPI.update(ticket.value.id, {
      ticket: { responsavel_id: member.colaboradorId },
    });
    emit('updated');
  } catch (error) {
    useAlert(t('TICKETS.HEADER.RESPONSIBLE_UPDATE_ERROR'));
  }
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
const editingWorklog = ref(null);
const openManualTimeModal = (worklog = null) => {
  editingWorklog.value = worklog;
  showManualTimeModal.value = true;
};
const onManualTimeSaved = () => {
  showManualTimeModal.value = false;
  editingWorklog.value = null;
  emit('updated');
};

// Apagar exige confirmação: primeiro clique destaca o botão, segundo clique
// (ou clicar fora) efetiva ou cancela — evita um modal só para isso.
const confirmingDeleteWorklogId = ref(null);
const cancelDeleteWorklog = () => {
  confirmingDeleteWorklogId.value = null;
};
const deleteWorklog = async worklog => {
  confirmingDeleteWorklogId.value = null;
  try {
    await TicketsAPI.deleteWorklog(ticket.value.id, worklog.id);
    emit('updated');
  } catch (error) {
    useAlert(t('TICKETS.MANUAL_TIME.DELETE_ERROR'));
  }
};
const askDeleteWorklog = worklog => {
  if (confirmingDeleteWorklogId.value === worklog.id) {
    deleteWorklog(worklog);
  } else {
    confirmingDeleteWorklogId.value = worklog.id;
  }
};

const formatWorklogDate = value =>
  value ? format(new Date(value), 'dd/MM/yyyy HH:mm') : '';

const isWorklogsAccordionOpen = ref(false);

const isArchiving = ref(false);
const toggleArchive = async () => {
  try {
    isArchiving.value = true;
    if (ticket.value.archived) {
      await store.dispatch('tickets/unarchive', ticket.value.id);
    } else {
      await store.dispatch('tickets/archive', ticket.value.id);
    }
    emit('updated');
  } catch (error) {
    useAlert(t('TICKETS.HEADER.ARCHIVE_ERROR'));
  } finally {
    isArchiving.value = false;
  }
};

onMounted(() => {
  if (!ticketStatuses.value.length) {
    store.dispatch('ticketStatuses/get');
  }
  if (!accountLabels.value?.length) {
    store.dispatch('labels/get');
  }
  if (!agentsList.value.length) {
    store.dispatch('agents/get');
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
      <Button
        v-if="isAdmin"
        faded
        slate
        size="small"
        class="shrink-0"
        :is-loading="isArchiving"
        :label="
          ticket.archived
            ? t('TICKETS.HEADER.UNARCHIVE')
            : t('TICKETS.HEADER.ARCHIVE')
        "
        @click="toggleArchive"
      />
    </div>

    <!-- Status / Time -->
    <div class="flex items-start gap-2">
      <div class="flex flex-col flex-1 min-w-0 gap-1">
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

      <div class="flex flex-col flex-1 min-w-0 gap-1">
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

    <!-- Membros (responsável + colaboradores em um único bloco) -->
    <div class="flex flex-col gap-1">
      <span class="text-xs font-medium text-n-slate-11">
        {{ t('TICKETS.HEADER.MEMBERS') }}
      </span>
      <div class="flex flex-wrap items-center gap-2">
        <div
          v-for="member in members"
          :key="member.key"
          v-tooltip="member.nome"
          class="relative group"
        >
          <Avatar
            :src="member.avatarUrl"
            :name="member.nome"
            :size="28"
            rounded-full
          />
          <button
            type="button"
            class="absolute -bottom-1 -right-1 flex items-center justify-center w-4 h-4 rounded-full"
            :class="
              member.isResponsible
                ? 'bg-n-amber-9 text-white'
                : 'hidden text-n-slate-11 bg-n-slate-3 group-hover:flex'
            "
            :title="
              member.isResponsible
                ? t('TICKETS.HEADER.RESPONSIBLE')
                : t('TICKETS.HEADER.MAKE_RESPONSIBLE')
            "
            @click="promoteToResponsible(member)"
          >
            <span class="text-[10px] i-lucide-star" />
          </button>
          <button
            v-if="!member.isResponsible"
            type="button"
            class="absolute -top-1 -right-1 items-center justify-center hidden w-4 h-4 text-white rounded-full bg-n-ruby-9 group-hover:flex"
            @click="removeMember(member)"
          >
            <span class="text-[10px] i-lucide-x" />
          </button>
        </div>
        <div v-on-clickaway="closeAddMemberDropdown" class="relative">
          <button
            type="button"
            class="flex items-center justify-center w-7 h-7 border border-dashed rounded-full text-n-slate-10 border-n-slate-6 hover:border-n-slate-8 hover:text-n-slate-11"
            @click="showAddMemberDropdown = !showAddMemberDropdown"
          >
            <span class="text-sm i-lucide-plus" />
          </button>
          <div
            v-show="showAddMemberDropdown"
            class="absolute z-[100] w-56 p-1 mt-1 overflow-y-auto border rounded-lg shadow-lg top-full max-h-60 bg-n-alpha-3 backdrop-blur-[100px] border-n-strong"
          >
            <button
              v-for="agent in memberOptions"
              :key="agent.id"
              type="button"
              class="flex items-center w-full gap-2 px-2 py-1.5 text-sm text-left rounded-md hover:bg-n-alpha-1"
              @click="addMember(agent)"
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

    <div class="flex items-center justify-between">
      <TimerWidget
        :ticket-id="ticket.id"
        :initial-state="myActiveTimer ? 'running' : 'stopped'"
        :initial-started-at="myActiveTimer?.iniciado_em"
        @worklog-created="onWorklogCreated"
      />
      <button
        type="button"
        class="text-xs text-n-slate-11 hover:underline"
        @click="openManualTimeModal()"
      >
        {{ t('TICKETS.TIMER.ADD_TIME') }}
      </button>
    </div>

    <!-- Registros de tempo -->
    <AccordionItem
      v-if="ticket.worklogs?.length"
      :title="t('TICKETS.MANUAL_TIME.LIST_TITLE')"
      :is-open="isWorklogsAccordionOpen"
      compact
      @toggle="isWorklogsAccordionOpen = !isWorklogsAccordionOpen"
    >
      <template #button>
        <span class="text-xs font-medium text-n-slate-11">
          {{ formatDuration(ticket.tempo_liquido_segundos || 0) }}
        </span>
      </template>
      <ul class="flex flex-col divide-y divide-n-weak">
        <li
          v-for="worklog in ticket.worklogs"
          :key="worklog.id"
          class="flex items-center justify-between gap-2 py-1.5 text-xs"
        >
          <div class="flex flex-col min-w-0">
            <span class="text-n-slate-12">
              {{ worklog.colaborador_nome }} —
              {{ formatDuration(worklog.duracao_segundos) }}
            </span>
            <span class="text-n-slate-10">
              {{ formatWorklogDate(worklog.inicio) }}
              <span v-if="worklog.motivo"> · {{ worklog.motivo }}</span>
            </span>
          </div>
          <div class="flex items-center gap-1 shrink-0">
            <button
              type="button"
              class="text-n-slate-11 hover:text-n-slate-12"
              :title="t('TICKETS.MANUAL_TIME.EDIT')"
              @click="openManualTimeModal(worklog)"
            >
              <span class="text-sm i-lucide-pencil" />
            </button>
            <button
              v-if="isAdmin"
              v-on-clickaway="cancelDeleteWorklog"
              type="button"
              class="hover:text-n-ruby-9"
              :class="
                confirmingDeleteWorklogId === worklog.id
                  ? 'text-n-ruby-9'
                  : 'text-n-slate-11'
              "
              :title="
                confirmingDeleteWorklogId === worklog.id
                  ? t('TICKETS.MANUAL_TIME.CONFIRM_DELETE')
                  : t('TICKETS.MANUAL_TIME.DELETE')
              "
              @click="askDeleteWorklog(worklog)"
            >
              <span class="text-sm i-lucide-trash-2" />
            </button>
          </div>
        </li>
      </ul>
    </AccordionItem>

    <woot-modal
      v-model:show="showManualTimeModal"
      :on-close="() => (showManualTimeModal = false)"
    >
      <ManualTimeEntryModal
        :ticket-id="ticket.id"
        :worklog="editingWorklog"
        @close="showManualTimeModal = false"
        @saved="onManualTimeSaved"
      />
    </woot-modal>
  </div>
</template>
