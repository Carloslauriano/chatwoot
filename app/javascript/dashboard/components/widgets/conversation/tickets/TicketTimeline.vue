<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { format } from 'date-fns';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import { describeTicketEvent } from 'dashboard/helper/ticketTimelineHelper';
import TicketsAPI from 'dashboard/api/tickets';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import HistoryTab from './HistoryTab.vue';
import TicketHeaderCard from './TicketHeaderCard.vue';

const props = defineProps({
  ticket: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['updated']);
const { t } = useI18n();
const router = useRouter();
const { accountId } = useAccount();

const activeTab = ref('timeline');
const events = ref([]);
const isLoadingTimeline = ref(false);
const historyTabRef = ref(null);

const ticket = computed(() => props.ticket);

const eventMeta = event => describeTicketEvent(event, t);

const formatEventDate = value => {
  if (!value) return '';
  return format(new Date(value), 'dd/MM/yyyy HH:mm');
};

const openConversation = () => {
  router.push({
    name: 'inbox_conversation',
    params: {
      accountId: accountId.value,
      conversation_id: ticket.value.conversation_id,
    },
  });
};

const loadTimeline = async () => {
  isLoadingTimeline.value = true;
  try {
    const response = await TicketsAPI.getTimeline(ticket.value.id);
    events.value = response.data || [];
  } catch (error) {
    useAlert(t('TICKETS.TIMELINE.FETCH_ERROR'));
  } finally {
    isLoadingTimeline.value = false;
  }
};

const onHeaderUpdated = () => {
  loadTimeline();
  historyTabRef.value?.reload();
  emit('updated');
};

watch(() => ticket.value.id, loadTimeline);
onMounted(loadTimeline);
</script>

<template>
  <div class="flex flex-col gap-3">
    <TicketHeaderCard :ticket="ticket" @updated="onHeaderUpdated" />

    <div class="flex gap-4 px-1 text-sm border-b border-n-weak">
      <button
        type="button"
        class="pb-2"
        :class="
          activeTab === 'timeline'
            ? 'border-b-2 border-n-blue-9 text-n-slate-12'
            : 'text-n-slate-11'
        "
        @click="activeTab = 'timeline'"
      >
        {{ $t('TICKETS.TABS.TIMELINE') }}
      </button>
      <button
        type="button"
        class="pb-2"
        :class="
          activeTab === 'history'
            ? 'border-b-2 border-n-blue-9 text-n-slate-12'
            : 'text-n-slate-11'
        "
        @click="activeTab = 'history'"
      >
        {{ $t('TICKETS.TABS.HISTORY') }}
      </button>
    </div>

    <div v-if="activeTab === 'timeline'">
      <div v-if="isLoadingTimeline" class="flex justify-center p-8">
        <Spinner />
      </div>
      <p v-else-if="!events.length" class="p-4 text-sm text-n-slate-11">
        {{ $t('TICKETS.TIMELINE.EMPTY') }}
      </p>
      <ul v-else class="flex flex-col py-1">
        <li v-for="(event, index) in events" :key="event.id" class="flex gap-3">
          <div class="flex flex-col items-center w-8">
            <span
              class="flex items-center justify-center w-8 h-8 text-white rounded-full shrink-0"
              :class="
                index === events.length - 1
                  ? 'bg-n-slate-8'
                  : eventMeta(event).dot
              "
            >
              <span
                :class="
                  index === events.length - 1
                    ? 'i-lucide-flag'
                    : eventMeta(event).icon
                "
                class="text-sm"
              />
            </span>
            <span
              v-if="index !== events.length - 1"
              class="flex-1 w-px bg-n-slate-4"
            />
          </div>

          <div class="flex-1 pb-8">
            <template v-if="index === events.length - 1">
              <div
                class="flex flex-wrap items-baseline justify-between gap-2 text-xs text-n-slate-11"
              >
                <span class="font-medium text-n-slate-12">{{
                  $t('TICKETS.TIMELINE.ORIGIN.LABEL')
                }}</span>
                <span>{{ formatEventDate(event.created_at) }}</span>
              </div>
              <div
                class="flex flex-wrap items-center justify-between gap-2 p-2 mt-1 text-sm rounded-lg rounded-tl-none bg-n-alpha-black2 text-n-slate-12"
              >
                <span>
                  #{{ ticket.id }} —
                  {{
                    $t('TICKETS.TIMELINE.ORIGIN.FROM_CONVERSATION', {
                      id: ticket.conversation_id,
                    })
                  }}
                </span>
                <Button
                  size="small"
                  faded
                  slate
                  icon="i-lucide-message-square"
                  :label="$t('TICKETS.SHOW.OPEN_CONVERSATION')"
                  @click="openConversation"
                />
              </div>
            </template>
            <template v-else>
              <div
                class="flex flex-wrap items-baseline justify-between gap-2 text-xs text-n-slate-11"
              >
                <span class="font-medium text-n-slate-12">{{
                  eventMeta(event).label
                }}</span>
                <span>{{ formatEventDate(event.created_at) }}</span>
              </div>
              <p
                v-if="event.payload?.texto"
                class="p-2 mt-1 text-sm rounded-lg rounded-tl-none bg-n-alpha-black2 text-n-slate-12"
              >
                {{ event.payload.texto }}
              </p>
            </template>
          </div>
        </li>
      </ul>
    </div>

    <HistoryTab v-else ref="historyTabRef" :ticket-id="ticket.id" />
  </div>
</template>
