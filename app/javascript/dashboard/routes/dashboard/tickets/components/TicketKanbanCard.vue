<script setup>
import { computed } from 'vue';
import Label from 'dashboard/components-next/label/Label.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
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
      <Avatar
        v-if="ticket.responsavel_nome"
        v-tooltip="ticket.responsavel_nome"
        :src="ticket.responsavel_avatar_url"
        :name="ticket.responsavel_nome"
        :size="24"
        rounded-full
        class="shrink-0"
      />
    </div>
  </div>
</template>
