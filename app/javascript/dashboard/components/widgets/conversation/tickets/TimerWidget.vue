<script setup>
import { ref, computed, watch, onMounted, onBeforeUnmount } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import TicketsAPI from 'dashboard/api/tickets';
import Button from 'dashboard/components-next/button/Button.vue';
import { activeTimerTicketId } from './activeTimerState';

const props = defineProps({
  ticketId: {
    type: [Number, String],
    required: true,
  },
  // 'stopped' | 'running' — initial hint from the ticket payload, if the
  // backend already reports an active timer for the current agent.
  initialState: {
    type: String,
    default: 'stopped',
  },
  initialStartedAt: {
    type: String,
    default: null,
  },
});

const emit = defineEmits(['worklogCreated']);
const { t } = useI18n();

// stopped | running
const timerState = ref(
  props.initialState === 'running' ? 'running' : 'stopped'
);
const startedAt = ref(
  props.initialStartedAt ? new Date(props.initialStartedAt) : null
);
const now = ref(new Date());
const isSubmitting = ref(false);
let tickInterval = null;

const elapsedSeconds = computed(() => {
  if (!startedAt.value) return 0;
  return Math.max(0, Math.floor((now.value - startedAt.value) / 1000));
});

const formattedElapsed = computed(() => {
  const total = elapsedSeconds.value;
  const hours = String(Math.floor(total / 3600)).padStart(2, '0');
  const minutes = String(Math.floor((total % 3600) / 60)).padStart(2, '0');
  const seconds = String(total % 60).padStart(2, '0');
  return `${hours}:${minutes}:${seconds}`;
});

const startTick = () => {
  if (tickInterval) return;
  tickInterval = setInterval(() => {
    now.value = new Date();
  }, 1000);
};

const stopTick = () => {
  if (tickInterval) {
    clearInterval(tickInterval);
    tickInterval = null;
  }
};

watch(
  timerState,
  value => {
    if (value === 'running') startTick();
    else stopTick();
  },
  { immediate: true }
);

// RN01 feedback: if this widget owns the running timer and a DIFFERENT
// ticket becomes the active one for this agent (started elsewhere in this
// session), show the non-blocking toast and reset locally — the backend
// already discarded the timer without creating a worklog.
watch(activeTimerTicketId, newTicketId => {
  if (
    timerState.value === 'running' &&
    newTicketId !== null &&
    String(newTicketId) !== String(props.ticketId)
  ) {
    timerState.value = 'stopped';
    startedAt.value = null;
    useAlert(t('TICKETS.TIMER.AUTO_PAUSED_TOAST', { ticketId: newTicketId }));
  }
});

const startTimer = async () => {
  try {
    isSubmitting.value = true;
    const response = await TicketsAPI.timerStart(props.ticketId);
    startedAt.value = new Date(response.data.iniciado_em || Date.now());
    timerState.value = 'running';
    activeTimerTicketId.value = props.ticketId;
  } catch (error) {
    useAlert(t('TICKETS.TIMER.START_ERROR'));
  } finally {
    isSubmitting.value = false;
  }
};

// Sem opção de pausar: parar sempre registra o worklog. Ao voltar, o
// colaborador dá start em um timer novo — não existe "retomar".
const stopTimer = async () => {
  try {
    isSubmitting.value = true;
    const response = await TicketsAPI.timerStop(props.ticketId, 'finalizado');
    timerState.value = 'stopped';
    startedAt.value = null;
    if (activeTimerTicketId.value === props.ticketId) {
      activeTimerTicketId.value = null;
    }
    emit('worklogCreated', response.data.worklog);
  } catch (error) {
    useAlert(t('TICKETS.TIMER.STOP_ERROR'));
  } finally {
    isSubmitting.value = false;
  }
};

onMounted(() => {
  if (timerState.value === 'running') {
    activeTimerTicketId.value = props.ticketId;
    startTick();
  }
});

onBeforeUnmount(stopTick);
</script>

<template>
  <div class="flex items-center gap-3">
    <template v-if="timerState === 'stopped'">
      <span class="text-sm font-mono text-n-slate-11">{{
        formattedElapsed
      }}</span>
      <Button
        icon="i-lucide-play"
        size="small"
        :label="$t('TICKETS.TIMER.START')"
        :disabled="isSubmitting"
        @click="startTimer"
      />
    </template>

    <template v-else>
      <span class="text-sm font-mono text-n-slate-12">{{
        formattedElapsed
      }}</span>
      <Button
        icon="i-lucide-square"
        size="small"
        slate
        :label="$t('TICKETS.TIMER.STOP')"
        :disabled="isSubmitting"
        @click="stopTimer"
      />
    </template>
  </div>
</template>
