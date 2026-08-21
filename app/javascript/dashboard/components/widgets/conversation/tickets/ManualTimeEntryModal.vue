<script setup>
import { reactive, computed, ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import TicketsAPI from 'dashboard/api/tickets';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  ticketId: {
    type: [Number, String],
    required: true,
  },
  worklog: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(['close', 'saved']);
const { t } = useI18n();

const isSubmitting = ref(false);

const formatDateTimeLocal = date => {
  const pad = n => String(n).padStart(2, '0');
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`;
};

const secondsToHms = totalSeconds => {
  const hours = String(Math.floor(totalSeconds / 3600)).padStart(2, '0');
  const minutes = String(Math.floor((totalSeconds % 3600) / 60)).padStart(
    2,
    '0'
  );
  const seconds = String(totalSeconds % 60).padStart(2, '0');
  return `${hours}:${minutes}:${seconds}`;
};

const hmsToSeconds = value => {
  const parts = String(value)
    .split(':')
    .map(part => parseInt(part, 10) || 0);
  while (parts.length < 3) parts.unshift(0);
  const [hours, minutes, seconds] = parts.slice(-3);
  return hours * 3600 + minutes * 60 + seconds;
};

const formState = reactive({
  duration: props.worklog
    ? secondsToHms(props.worklog.duracao_segundos)
    : '00:30:00',
  startedAt: props.worklog?.inicio
    ? formatDateTimeLocal(new Date(props.worklog.inicio))
    : formatDateTimeLocal(new Date()),
  reason: props.worklog?.motivo || '',
});

const isSubmitDisabled = computed(() => {
  return hmsToSeconds(formState.duration) <= 0 || isSubmitting.value;
});

const onClose = () => emit('close');

const save = async () => {
  if (isSubmitDisabled.value) return;

  const payload = {
    duracao_segundos: hmsToSeconds(formState.duration),
    inicio: new Date(formState.startedAt).toISOString(),
    motivo: formState.reason || undefined,
  };

  try {
    isSubmitting.value = true;
    const response = props.worklog
      ? await TicketsAPI.updateWorklog(
          props.ticketId,
          props.worklog.id,
          payload
        )
      : await TicketsAPI.createWorklog(props.ticketId, payload);
    useAlert(t('TICKETS.MANUAL_TIME.SUCCESS'));
    emit('saved', response.data);
  } catch (error) {
    useAlert(t('TICKETS.MANUAL_TIME.ERROR'));
  } finally {
    isSubmitting.value = false;
  }
};

onMounted(() => {});
</script>

<template>
  <div class="flex flex-col gap-4">
    <woot-modal-header :header-title="$t('TICKETS.MANUAL_TIME.TITLE')" />

    <div class="flex flex-col gap-4 px-8 pb-4">
      <woot-input
        v-model="formState.duration"
        class="w-full"
        :label="$t('TICKETS.MANUAL_TIME.DURATION.LABEL')"
        placeholder="00:30:00"
      />
      <label class="flex flex-col gap-1">
        <span class="text-sm font-medium text-n-slate-12">
          {{ $t('TICKETS.MANUAL_TIME.STARTED_AT.LABEL') }}
        </span>
        <input
          v-model="formState.startedAt"
          type="datetime-local"
          class="text-sm rounded-xl border border-n-weak"
        />
      </label>
      <woot-input
        v-model="formState.reason"
        class="w-full"
        :label="$t('TICKETS.MANUAL_TIME.REASON.LABEL')"
        :placeholder="$t('TICKETS.MANUAL_TIME.REASON.PLACEHOLDER')"
      />

      <div class="flex items-center justify-end w-full gap-2 mt-2">
        <Button
          faded
          slate
          type="reset"
          :label="$t('TICKETS.MANUAL_TIME.CANCEL')"
          @click.prevent="onClose"
        />
        <Button
          type="submit"
          :label="$t('TICKETS.MANUAL_TIME.SUBMIT')"
          :disabled="isSubmitDisabled"
          :is-loading="isSubmitting"
          @click.prevent="save"
        />
      </div>
    </div>
  </div>
</template>
