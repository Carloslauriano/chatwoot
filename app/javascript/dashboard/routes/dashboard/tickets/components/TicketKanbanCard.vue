<script setup>
import { computed } from 'vue';
import Label from 'dashboard/components-next/label/Label.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import { useMapGetter } from 'dashboard/composables/store';
import { formatDuration } from 'shared/helpers/timeHelper';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import {
  PRIORITY_COLOR,
  PRIORITY_ICON,
  colorForLabel,
} from 'dashboard/helper/ticketCardHelper';

const props = defineProps({
  ticket: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['open']);
const { getPlainText } = useMessageFormatter();

const totalWorked = computed(() =>
  formatDuration(props.ticket.tempo_liquido_segundos || 0)
);

const descriptionPreview = computed(() =>
  getPlainText(props.ticket.descricao || '')
);

// Agentes da conta inteira (mesma fonte que o TicketHeaderCard) para resolver
// o avatar dos colaboradores, já que assignments não traz avatar no payload.
const agentsList = useMapGetter('agents/getActiveAgents');
const agentFor = colaboradorId =>
  agentsList.value.find(agent => agent.id === colaboradorId);

const members = computed(() => {
  const assignments = props.ticket.assignments || [];
  const responsavelId = props.ticket.responsavel_id;

  const responsavelMember = responsavelId
    ? {
        key: `responsavel-${responsavelId}`,
        nome: props.ticket.responsavel_nome,
        avatarUrl: props.ticket.responsavel_avatar_url,
      }
    : null;

  const otherMembers = assignments
    .filter(assignment => assignment.colaborador_id !== responsavelId)
    .map(assignment => ({
      key: `assignment-${assignment.id}`,
      nome: assignment.colaborador_nome,
      avatarUrl: agentFor(assignment.colaborador_id)?.thumbnail,
    }));

  return responsavelMember
    ? [responsavelMember, ...otherMembers]
    : otherMembers;
});
</script>

<template>
  <div
    class="flex flex-col w-full gap-2 p-3 mb-2 rounded-lg outline-1 outline outline-n-container -outline-offset-1 bg-n-solid-2 cursor-grab hover:outline-n-slate-6"
    @click="emit('open', ticket)"
  >
    <div class="flex items-start justify-between gap-2">
      <div
        v-if="ticket.label_list?.length"
        class="flex flex-wrap items-center gap-1"
      >
        <Label
          v-for="labelName in ticket.label_list"
          :key="labelName"
          :label="labelName"
          :color="colorForLabel(labelName)"
          compact
        />
      </div>
      <Label
        class="ml-auto shrink-0"
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

    <p class="text-sm font-semibold text-n-slate-12">
      {{ ticket.titulo }}
    </p>
    <p v-if="descriptionPreview" class="text-xs text-n-slate-11 line-clamp-2">
      {{ descriptionPreview }}
    </p>

    <div class="flex items-center justify-between gap-2 mt-1">
      <div class="flex items-center gap-3 text-xs text-n-slate-10">
        <span v-if="ticket.team_name" class="truncate max-w-[110px]">
          {{ ticket.team_name }}
        </span>
        <span
          v-if="ticket.tempo_liquido_segundos"
          class="flex items-center gap-1 shrink-0"
        >
          <span class="text-sm i-lucide-clock" />
          {{ totalWorked }}
        </span>
      </div>
      <div v-if="members.length" class="flex items-center shrink-0 -space-x-2">
        <Avatar
          v-for="member in members"
          :key="member.key"
          v-tooltip="member.nome"
          :src="member.avatarUrl"
          :name="member.nome"
          :size="24"
          rounded-full
          class="ring-2 ring-n-solid-2"
        />
      </div>
    </div>
  </div>
</template>
