<script setup>
import { computed } from 'vue';
import Draggable from 'vuedraggable';
import TicketKanbanCard from './TicketKanbanCard.vue';

const props = defineProps({
  title: {
    type: String,
    required: true,
  },
  ticketStatusId: {
    type: [Number, String],
    required: true,
  },
  tickets: {
    type: Array,
    required: true,
  },
});

const emit = defineEmits(['moved', 'open']);

// v-model local — Draggable precisa de um array editável; a fonte de
// verdade continua sendo a store, atualizada via evento @change.
const localTickets = computed({
  get: () => props.tickets,
  set: () => {},
});

const handleChange = event => {
  if (event.added) {
    emit('moved', {
      ticketId: event.added.element.id,
      ticketStatusId: props.ticketStatusId,
    });
  }
};
</script>

<template>
  <div class="flex flex-col w-full min-w-[260px] gap-3">
    <div class="flex items-center gap-2 px-1">
      <h3 class="text-sm font-medium text-n-slate-12">{{ title }}</h3>
      <span
        class="flex items-center justify-center px-1.5 h-5 min-w-[20px] text-xs font-medium rounded-full bg-n-alpha-2 text-n-slate-11"
      >
        {{ tickets.length }}
      </span>
    </div>
    <Draggable
      v-model="localTickets"
      class="flex flex-col flex-1 min-h-[120px] p-2 rounded-lg bg-n-alpha-1"
      group="tickets-kanban"
      item-key="id"
      tag="div"
      @change="handleChange"
    >
      <template #item="{ element }">
        <TicketKanbanCard :ticket="element" @open="emit('open', $event)" />
      </template>
    </Draggable>
  </div>
</template>
