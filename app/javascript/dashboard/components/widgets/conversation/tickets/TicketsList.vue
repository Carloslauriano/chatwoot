<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import TicketsAPI from 'dashboard/api/tickets';
import CreateOrLinkTicketModal from './CreateOrLinkTicketModal.vue';
import TicketQuickViewModal from './TicketQuickViewModal.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Label from 'dashboard/components-next/label/Label.vue';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const linkedTicket = ref(null);
const isLoading = ref(false);
const shouldShowCreateModal = ref(false);
const shouldShowQuickView = ref(false);

const hasTicket = computed(() => !!linkedTicket.value);

const loadLinkedTicket = async () => {
  isLoading.value = true;
  linkedTicket.value = null;
  try {
    const response = await TicketsAPI.getByConversation(props.conversationId);
    linkedTicket.value = (response.data || [])[0] || null;
  } catch (error) {
    linkedTicket.value = null;
  } finally {
    isLoading.value = false;
  }
};

const openCreateModal = () => {
  shouldShowCreateModal.value = true;
};

const closeCreateModal = () => {
  shouldShowCreateModal.value = false;
  loadLinkedTicket();
};

const openQuickView = () => {
  shouldShowQuickView.value = true;
};

const closeQuickView = () => {
  shouldShowQuickView.value = false;
  loadLinkedTicket();
};

watch(() => props.conversationId, loadLinkedTicket);
onMounted(loadLinkedTicket);
</script>

<template>
  <div>
    <div v-if="isLoading" class="flex justify-center p-8">
      <Spinner />
    </div>

    <div
      v-else-if="!hasTicket"
      class="flex flex-col items-start gap-2 px-4 pt-3 pb-4"
    >
      <p class="text-sm text-n-slate-11">{{ $t('TICKETS.NO_TICKET') }}</p>
      <NextButton
        ghost
        xs
        icon="i-lucide-plus"
        :label="$t('TICKETS.CREATE_OR_LINK_BUTTON')"
        @click="openCreateModal"
      />
    </div>

    <button
      v-else
      type="button"
      class="flex items-center justify-between w-full gap-2 px-4 py-3 text-left hover:bg-n-alpha-black2"
      @click="openQuickView"
    >
      <span class="text-sm font-medium text-n-slate-12">
        #{{ linkedTicket.id }} — {{ linkedTicket.titulo }}
      </span>
      <Label
        v-if="linkedTicket.ticket_status_name"
        :label="linkedTicket.ticket_status_name"
        color="teal"
        compact
      />
    </button>

    <woot-modal
      v-model:show="shouldShowCreateModal"
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
      v-model:show="shouldShowQuickView"
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
