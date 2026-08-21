<script setup>
import { computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Label from 'dashboard/components-next/label/Label.vue';

const { t } = useI18n();
const store = useStore();
const router = useRouter();
const { accountId } = useAccount();

const tickets = useMapGetter('tickets/getTickets');
const uiFlags = useMapGetter('tickets/getUIFlags');
const { getPlainText } = useMessageFormatter();

const PRIORITY_COLOR = {
  baixa: 'slate',
  media: 'blue',
  alta: 'amber',
  critica: 'ruby',
};

const STATUS_MACRO_LABEL = {
  caixa_entrada: 'Caixa de Entrada',
  a_fazer: 'A Fazer',
  fazendo: 'Fazendo',
  aguardando_versao: 'Aguardando Versão',
  resolvido: 'Resolvido',
};

const isEmpty = computed(
  () => !uiFlags.value.isFetching && tickets.value.length === 0
);

const openTicket = ticket => {
  router.push({
    name: 'ticket_show',
    params: {
      accountId: accountId.value,
      ticketId: ticket.id,
    },
  });
};

onMounted(() => {
  store.dispatch('tickets/fetchAll');
});
</script>

<template>
  <div class="flex flex-col w-full h-full p-6 overflow-auto">
    <h1 class="mb-4 text-xl font-medium text-n-slate-12">
      {{ t('SIDEBAR.TICKETS_LIST') }}
    </h1>

    <p v-if="isEmpty" class="text-n-slate-11">
      {{ t('SIDEBAR.NO_ITEMS') }}
    </p>

    <div
      v-else
      class="grid w-full grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3"
    >
      <CardLayout
        v-for="ticket in tickets"
        :key="ticket.id"
        class="cursor-pointer"
        @click="openTicket(ticket)"
      >
        <div class="flex flex-col w-full gap-2 px-6">
          <div class="flex items-center justify-between">
            <span class="text-sm font-medium text-n-slate-12">
              #{{ ticket.id }} — {{ ticket.titulo }}
            </span>
            <Label
              :label="ticket.prioridade"
              :color="PRIORITY_COLOR[ticket.prioridade] || 'slate'"
              compact
            />
          </div>
          <p class="text-sm text-n-slate-11 line-clamp-2">
            {{ getPlainText(ticket.descricao || '') }}
          </p>
          <div class="flex items-center justify-between mt-2">
            <Label
              :label="ticket.team_name || ticket.setor_atual"
              color="iris"
              compact
            />
            <Label
              :label="
                STATUS_MACRO_LABEL[ticket.status_macro] || ticket.status_macro
              "
              color="teal"
              compact
            />
          </div>
        </div>
      </CardLayout>
    </div>
  </div>
</template>
