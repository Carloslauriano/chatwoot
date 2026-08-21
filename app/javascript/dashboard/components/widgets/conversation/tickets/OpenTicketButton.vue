<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import TicketsAPI from 'dashboard/api/tickets';
import ButtonV4 from 'dashboard/components-next/button/Button.vue';
import CreateOrLinkTicketModal from './CreateOrLinkTicketModal.vue';
import TicketQuickViewModal from './TicketQuickViewModal.vue';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const { t } = useI18n();

const linkedTicket = ref(null);
const showCreateModal = ref(false);
const showQuickView = ref(false);

const hasTicket = computed(() => !!linkedTicket.value);

const loadLinkedTicket = async () => {
  try {
    const response = await TicketsAPI.getByConversation(props.conversationId);
    linkedTicket.value = (response.data || [])[0] || null;
  } catch (error) {
    linkedTicket.value = null;
  }
};

const onClick = () => {
  if (hasTicket.value) {
    showQuickView.value = true;
  } else {
    showCreateModal.value = true;
  }
};

const closeCreateModal = () => {
  showCreateModal.value = false;
  loadLinkedTicket();
};

const closeQuickView = () => {
  showQuickView.value = false;
  loadLinkedTicket();
};

watch(() => props.conversationId, loadLinkedTicket);
onMounted(loadLinkedTicket);
</script>

<template>
  <div class="relative flex items-center">
    <ButtonV4
      v-tooltip="t('TICKETS.OPEN_TICKET_BUTTON')"
      size="sm"
      variant="ghost"
      color="slate"
      icon="i-lucide-ticket"
      :label="t('TICKETS.OPEN_TICKET_BUTTON')"
      @click="onClick"
    />

    <woot-modal
      v-model:show="showCreateModal"
      :on-close="closeCreateModal"
      :close-on-backdrop-click="false"
      class="!items-start [&>div]:!top-12 [&>div]:sticky"
    >
      <CreateOrLinkTicketModal
        :conversation-id="conversationId"
        @close="closeCreateModal"
      />
    </woot-modal>

    <woot-modal
      v-model:show="showQuickView"
      :on-close="closeQuickView"
      size="medium"
      class="!items-start [&>div]:!top-12 [&>div]:sticky"
    >
      <TicketQuickViewModal
        v-if="linkedTicket"
        :ticket-id="linkedTicket.id"
        @close="closeQuickView"
        @updated="loadLinkedTicket"
      />
    </woot-modal>
  </div>
</template>
