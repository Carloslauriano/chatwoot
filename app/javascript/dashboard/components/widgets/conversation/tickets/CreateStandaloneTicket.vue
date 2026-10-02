<script setup>
import { reactive, computed, ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import TicketsAPI from 'dashboard/api/tickets';
import MultiselectDropdown from 'shared/components/ui/MultiselectDropdown.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import TicketLabelPicker from './TicketLabelPicker.vue';

const props = defineProps({
  // Time atualmente filtrado no Kanban (ex. "Dev"), se houver — usado para
  // pré-selecionar o time do novo ticket com a "área ativa" da tela.
  defaultTeamId: {
    type: [Number, String],
    default: null,
  },
  // Preenchido quando o ticket é criado a partir do botão "+" de uma coluna
  // específica do Kanban — o ticket já nasce direto naquele status, sem
  // depender do status padrão (posição 1) do time.
  defaultTicketStatusId: {
    type: [Number, String],
    default: null,
  },
});

const emit = defineEmits(['close', 'created']);
const { t } = useI18n();

const store = useStore();
const agentsList = useMapGetter('agents/getActiveAgents');
const teams = useMapGetter('teams/getTeams');
const accountLabels = useMapGetter('labels/getLabels');

const isCreating = ref(false);

const formState = reactive({
  titulo: '',
  descricao: '',
  prioridade: '',
  responsavelId: '',
  teamId: null,
  labels: [],
});

const priorityOptions = [
  { id: 'baixa', name: t('TICKETS.PRIORITY_OPTIONS.BAIXA') },
  { id: 'media', name: t('TICKETS.PRIORITY_OPTIONS.MEDIA') },
  { id: 'alta', name: t('TICKETS.PRIORITY_OPTIONS.ALTA') },
  { id: 'critica', name: t('TICKETS.PRIORITY_OPTIONS.CRITICA') },
];

const teamOptions = computed(() => [
  { id: null, name: t('TICKETS.CREATE.TEAM.NONE') },
  ...(teams.value || []),
]);

const selectedPriority = computed(
  () => priorityOptions.find(option => option.id === formState.prioridade) || {}
);

const selectedResponsible = computed(
  () =>
    agentsList.value.find(agent => agent.id === formState.responsavelId) || {}
);

const selectedTeam = computed(
  () => teamOptions.value.find(team => team.id === formState.teamId) || {}
);

// Se houver um time marcado como padrão para tickets, pula o seletor.
const defaultTeam = computed(() =>
  (teams.value || []).find(team => team.default_for_tickets)
);

const isSubmitDisabled = computed(() => {
  return (
    !formState.titulo.trim() ||
    !formState.descricao.trim() ||
    !formState.prioridade ||
    !formState.responsavelId ||
    isCreating.value
  );
});

const onSelectPriority = item => {
  formState.prioridade = item.id;
};

const onSelectResponsible = item => {
  formState.responsavelId = item.id;
};

const onSelectTeam = item => {
  formState.teamId = item.id || null;
};

const toggleLabel = title => {
  formState.labels = formState.labels.includes(title)
    ? formState.labels.filter(label => label !== title)
    : [...formState.labels, title];
};

onMounted(async () => {
  if (!accountLabels.value?.length) {
    store.dispatch('labels/get');
  }
  if (!agentsList.value?.length) {
    store.dispatch('agents/get');
  }
  if (!teams.value?.length) {
    await store.dispatch('teams/get');
  }
  if (props.defaultTeamId) {
    formState.teamId = Number(props.defaultTeamId);
  } else if (defaultTeam.value) {
    formState.teamId = defaultTeam.value.id;
  }
});

const onClose = () => emit('close');

const createTicket = async () => {
  if (isSubmitDisabled.value) return;

  const payload = {
    titulo: formState.titulo,
    descricao: formState.descricao,
    prioridade: formState.prioridade,
    responsavel_id: formState.responsavelId,
  };
  if (formState.teamId) payload.team_id = formState.teamId;
  if (props.defaultTicketStatusId) {
    payload.ticket_status_id = Number(props.defaultTicketStatusId);
  }

  try {
    isCreating.value = true;
    const response = await TicketsAPI.create({ ticket: payload });
    const ticket = response.data;

    if (formState.labels.length) {
      await TicketsAPI.updateLabels(ticket.id, formState.labels);
    }

    useAlert(t('TICKETS.CREATE.SUCCESS'));
    emit('created', ticket);
  } catch (error) {
    useAlert(t('TICKETS.CREATE.ERROR'));
  } finally {
    isCreating.value = false;
  }
};
</script>

<template>
  <div class="flex flex-col gap-4">
    <label class="flex flex-col gap-1">
      <span class="text-sm font-medium text-n-slate-12">
        {{ $t('TICKETS.CREATE.TITLE.LABEL') }}
      </span>
      <input
        v-model="formState.titulo"
        type="text"
        class="text-sm rounded-xl border border-n-weak"
        :placeholder="$t('TICKETS.CREATE.TITLE.PLACEHOLDER')"
      />
    </label>

    <div class="flex flex-col gap-1">
      <span class="text-sm font-medium text-n-slate-12">
        {{ $t('TICKETS.CREATE.DESCRIPTION.LABEL') }}
      </span>
      <WootMessageEditor
        v-model="formState.descricao"
        channel-type="Context::Default"
        :enable-canned-responses="false"
        :placeholder="$t('TICKETS.CREATE.DESCRIPTION.PLACEHOLDER')"
      />
    </div>

    <div class="flex flex-col gap-1">
      <span class="text-sm font-medium text-n-slate-12">
        {{ $t('TICKETS.CREATE.PRIORITY.LABEL') }}
      </span>
      <MultiselectDropdown
        :options="priorityOptions"
        :selected-item="selectedPriority"
        :multiselector-placeholder="$t('TICKETS.CREATE.PRIORITY.PLACEHOLDER')"
        :input-placeholder="$t('TICKETS.CREATE.PRIORITY.PLACEHOLDER')"
        :has-thumbnail="false"
        @select="onSelectPriority"
      />
    </div>

    <div class="flex flex-col gap-1">
      <span class="text-sm font-medium text-n-slate-12">
        {{ $t('TICKETS.CREATE.RESPONSIBLE.LABEL') }}
      </span>
      <MultiselectDropdown
        :options="agentsList"
        :selected-item="selectedResponsible"
        :multiselector-placeholder="
          $t('TICKETS.CREATE.RESPONSIBLE.PLACEHOLDER')
        "
        :input-placeholder="$t('TICKETS.CREATE.RESPONSIBLE.PLACEHOLDER')"
        @select="onSelectResponsible"
      />
    </div>

    <div v-if="!defaultTeam" class="flex flex-col gap-1">
      <span class="text-sm font-medium text-n-slate-12">
        {{ $t('TICKETS.CREATE.TEAM.LABEL') }}
      </span>
      <MultiselectDropdown
        :options="teamOptions"
        :selected-item="selectedTeam"
        :multiselector-placeholder="$t('TICKETS.CREATE.TEAM.PLACEHOLDER')"
        :input-placeholder="$t('TICKETS.CREATE.TEAM.PLACEHOLDER')"
        :has-thumbnail="false"
        @select="onSelectTeam"
      />
    </div>

    <div class="flex flex-col gap-1">
      <span class="text-sm font-medium text-n-slate-12">
        {{ $t('TICKETS.CREATE.LABELS.LABEL') }}
      </span>
      <TicketLabelPicker
        :account-labels="accountLabels"
        :selected-labels="formState.labels"
        @add="label => toggleLabel(label.title)"
        @remove="toggleLabel"
      />
    </div>

    <div class="flex items-center justify-end w-full gap-2 mt-2">
      <Button
        faded
        slate
        type="reset"
        :label="$t('TICKETS.CREATE.CANCEL')"
        @click.prevent="onClose"
      />
      <Button
        type="submit"
        :label="$t('TICKETS.CREATE.SUBMIT')"
        :disabled="isSubmitDisabled"
        :is-loading="isCreating"
        @click.prevent="createTicket"
      />
    </div>
  </div>
</template>
