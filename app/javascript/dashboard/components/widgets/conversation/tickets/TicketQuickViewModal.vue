<script setup>
import { ref, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import TicketsAPI from 'dashboard/api/tickets';
import { useAccount } from 'dashboard/composables/useAccount';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import {
  describeTicketEvent,
  ticketEventText,
  activityTimeAgo,
} from 'dashboard/helper/ticketTimelineHelper';
import TicketHeaderCard from './TicketHeaderCard.vue';

const props = defineProps({
  ticketId: {
    type: [Number, String],
    required: true,
  },
});

const emit = defineEmits(['updated']);
const { t } = useI18n();
const router = useRouter();
const { accountId } = useAccount();

const ticket = ref(null);
const isLoading = ref(false);
const events = ref([]);
const isLoadingActivity = ref(false);

const loadTicket = async () => {
  isLoading.value = true;
  try {
    const response = await TicketsAPI.show(props.ticketId);
    ticket.value = response.data;
  } catch (error) {
    ticket.value = null;
  } finally {
    isLoading.value = false;
  }
};

const loadActivity = async () => {
  isLoadingActivity.value = true;
  try {
    const response = await TicketsAPI.getTimeline(props.ticketId);
    events.value = response.data || [];
  } catch (error) {
    events.value = [];
  } finally {
    isLoadingActivity.value = false;
  }
};

const onUpdated = () => {
  loadTicket();
  emit('updated');
};

const openConversation = () => {
  if (!ticket.value) return;
  router.push({
    name: 'inbox_conversation',
    params: {
      accountId: accountId.value,
      conversation_id: ticket.value.conversation_id,
    },
  });
};

watch(
  () => props.ticketId,
  () => {
    loadTicket();
    loadActivity();
  }
);

onMounted(() => {
  loadTicket();
  loadActivity();
});
</script>

<template>
  <div class="flex flex-col h-auto overflow-auto">
    <woot-modal-header
      :header-title="t('TICKETS.QUICK_VIEW.TITLE', { id: ticketId })"
    />

    <div class="flex flex-col gap-6 px-8 pb-6 lg:flex-row">
      <div v-if="isLoading" class="flex justify-center flex-1 p-8">
        <Spinner />
      </div>
      <template v-else-if="ticket">
        <div class="flex-1 min-w-0">
          <TicketHeaderCard :ticket="ticket" @updated="onUpdated" />
        </div>

        <div class="flex flex-col flex-shrink-0 gap-3 lg:w-80">
          <span class="text-xs font-medium text-n-slate-11">
            {{ t('TICKETS.QUICK_VIEW.ACTIVITY') }}
          </span>
          <div v-if="isLoadingActivity" class="flex justify-center p-4">
            <Spinner />
          </div>
          <p v-else-if="!events.length" class="text-xs text-n-slate-11">
            {{ t('TICKETS.TIMELINE.EMPTY') }}
          </p>
          <ul v-else class="flex flex-col gap-3 overflow-y-auto max-h-[32rem]">
            <li
              v-for="(event, index) in events"
              :key="event.id"
              class="flex gap-2 text-xs"
            >
              <template v-if="index === events.length - 1">
                <span
                  class="flex items-center justify-center w-6 h-6 text-white rounded-full shrink-0 bg-n-slate-8"
                >
                  <span class="text-[11px] i-lucide-flag" />
                </span>
                <div class="flex flex-col gap-1">
                  <span class="text-n-slate-12">
                    {{
                      t('TICKETS.TIMELINE.ORIGIN.FROM_CONVERSATION', {
                        id: ticket.conversation_id,
                      })
                    }}
                  </span>
                  <Button
                    size="small"
                    faded
                    slate
                    icon="i-lucide-message-square"
                    :label="t('TICKETS.SHOW.OPEN_CONVERSATION')"
                    class="w-fit"
                    @click="openConversation"
                  />
                </div>
              </template>
              <template v-else>
                <Avatar
                  v-if="event.autor_nome"
                  :src="event.autor_avatar_url"
                  :name="event.autor_nome"
                  :size="24"
                  rounded-full
                  class="shrink-0"
                />
                <span
                  v-else
                  class="flex items-center justify-center w-6 h-6 text-white rounded-full shrink-0"
                  :class="describeTicketEvent(event, t).dot"
                >
                  <span
                    :class="describeTicketEvent(event, t).icon"
                    class="text-[11px]"
                  />
                </span>
                <div class="flex flex-col gap-0.5">
                  <span class="text-n-slate-12">
                    {{ describeTicketEvent(event, t).label }}
                  </span>
                  <span v-if="ticketEventText(event)" class="text-n-slate-11">
                    {{ ticketEventText(event) }}
                  </span>
                  <span class="text-n-slate-10">
                    {{ activityTimeAgo(event.created_at) }}
                  </span>
                </div>
              </template>
            </li>
          </ul>
        </div>
      </template>
    </div>
  </div>
</template>
