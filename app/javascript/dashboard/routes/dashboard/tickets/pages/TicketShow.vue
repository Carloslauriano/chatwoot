<script setup>
import { ref, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import TicketsAPI from 'dashboard/api/tickets';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import TicketTimeline from 'dashboard/components/widgets/conversation/tickets/TicketTimeline.vue';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();
const { accountId } = useAccount();

const ticket = ref(null);
const isLoading = ref(false);
const loadError = ref(false);

const fetchTicket = async () => {
  isLoading.value = true;
  loadError.value = false;
  try {
    const response = await TicketsAPI.show(route.params.ticketId);
    ticket.value = response.data;
  } catch (error) {
    loadError.value = true;
  } finally {
    isLoading.value = false;
  }
};

const goBackToList = () => {
  router.push({
    name: 'tickets_index',
    params: { accountId: accountId.value },
  });
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

watch(() => route.params.ticketId, fetchTicket);
onMounted(fetchTicket);
</script>

<template>
  <div class="flex flex-col w-full h-full p-6 overflow-auto">
    <div class="flex items-center justify-between mb-4">
      <div class="flex items-center gap-2">
        <Button
          icon="i-lucide-arrow-left"
          ghost
          slate
          xs
          @click="goBackToList"
        />
        <h1 v-if="ticket" class="text-xl font-medium text-n-slate-12">
          #{{ ticket.id }} — {{ ticket.titulo }}
        </h1>
      </div>
      <Button
        v-if="ticket"
        icon="i-lucide-message-square"
        faded
        slate
        xs
        :label="t('TICKETS.SHOW.OPEN_CONVERSATION')"
        @click="openConversation"
      />
    </div>

    <div v-if="isLoading" class="flex justify-center p-8">
      <Spinner />
    </div>

    <p v-else-if="loadError" class="text-n-slate-11">
      {{ t('TICKETS.SHOW.LOAD_ERROR') }}
    </p>

    <div v-else-if="ticket" class="max-w-3xl">
      <TicketTimeline :ticket="ticket" @updated="fetchTicket" />
    </div>
  </div>
</template>
