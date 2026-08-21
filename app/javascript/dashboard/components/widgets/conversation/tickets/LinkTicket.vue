<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useMapGetter } from 'dashboard/composables/store';
import TicketsAPI from 'dashboard/api/tickets';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
  contactId: {
    type: [Number, String],
    default: null,
  },
});

const emit = defineEmits(['close', 'linked']);
const { t } = useI18n();

const currentChat = useMapGetter('getSelectedChat');
const contactId = computed(
  () => props.contactId || currentChat.value?.meta?.sender?.id
);

const tickets = ref([]);
const isLoading = ref(false);
const isLinking = ref(false);
const selectedTicketId = ref(null);

const hasTickets = computed(() => tickets.value.length > 0);

const loadOpenTickets = async () => {
  if (!contactId.value) return;
  isLoading.value = true;
  try {
    const response = await TicketsAPI.searchOpenByContact(contactId.value);
    tickets.value = response.data || [];
  } catch (error) {
    tickets.value = [];
  } finally {
    isLoading.value = false;
  }
};

const onSelectTicket = ticketId => {
  selectedTicketId.value = ticketId;
};

const isSubmitDisabled = computed(
  () => !selectedTicketId.value || isLinking.value
);

const onClose = () => emit('close');

const linkTicket = async () => {
  if (isSubmitDisabled.value) return;
  try {
    isLinking.value = true;
    const response = await TicketsAPI.linkConversation(
      selectedTicketId.value,
      props.conversationId
    );
    useAlert(t('TICKETS.LINK.SUCCESS'));
    emit('linked', response.data);
  } catch (error) {
    if (error?.response?.status === 409) {
      useAlert(t('TICKETS.LINK.RESOLVED_ERROR'));
    } else {
      useAlert(t('TICKETS.LINK.ERROR'));
    }
  } finally {
    isLinking.value = false;
  }
};

onMounted(loadOpenTickets);
</script>

<template>
  <div class="flex flex-col gap-3">
    <div v-if="isLoading" class="flex justify-center p-8">
      <Spinner />
    </div>
    <p v-else-if="!hasTickets" class="text-sm text-n-slate-11">
      {{ $t('TICKETS.LINK.EMPTY') }}
    </p>
    <ul v-else class="flex flex-col gap-1 max-h-[220px] overflow-y-auto">
      <li
        v-for="ticket in tickets"
        :key="ticket.id"
        class="flex items-center justify-between p-2 text-sm rounded-lg cursor-pointer hover:bg-n-alpha-black2"
        :class="{ 'bg-n-alpha-black2': selectedTicketId === ticket.id }"
        @click="onSelectTicket(ticket.id)"
      >
        <span>#{{ ticket.id }} — {{ ticket.titulo }}</span>
        <span class="text-xs text-n-slate-11">{{ ticket.setor_atual }}</span>
      </li>
    </ul>

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
        :label="$t('TICKETS.LINK.SUBMIT')"
        :disabled="isSubmitDisabled"
        :is-loading="isLinking"
        @click.prevent="linkTicket"
      />
    </div>
  </div>
</template>
