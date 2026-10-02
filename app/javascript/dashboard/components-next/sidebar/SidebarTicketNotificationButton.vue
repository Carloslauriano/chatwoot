<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';
import { useMapGetter } from 'dashboard/composables/store';
import NotificationsAPI from 'dashboard/api/notifications';
import types from 'dashboard/store/mutation-types';
import Button from 'dashboard/components-next/button/Button.vue';
import SidebarUnreadBadge from './SidebarUnreadBadge.vue';

const TICKET_ACTIVITY_TYPE = 'ticket_activity';

const store = useStore();
const router = useRouter();
const { t } = useI18n();

const [isOpen, toggleOpen] = useToggle(false);
const unreadCount = ref(0);

const allNotifications = useMapGetter(
  'notifications/getFilteredNotificationsV4'
);
const ticketNotifications = computed(() =>
  allNotifications
    .value({ sortOrder: 'desc' })
    .filter(
      notification => notification.notificationType === TICKET_ACTIVITY_TYPE
    )
);

const fetchUnreadCount = async () => {
  try {
    const { data } = await NotificationsAPI.getUnreadCount({
      notification_type: TICKET_ACTIVITY_TYPE,
    });
    unreadCount.value = data;
  } catch (error) {
    // ignore, badge stays at last known value
  }
};

// ActionCable já entrega qualquer notification.created/updated genericamente
// no store (ver onNotificationCreated/onNotificationUpdated em actionCable.js),
// então qualquer nova atividade de ticket, ou leitura em outra aba/sessão, já
// muda ticketNotifications reativamente — só precisamos reconsultar a contagem
// autoritativa do backend quando isso acontecer (o store não guarda a soma
// exata para além dos 15 itens carregados na primeira página).
watch(ticketNotifications, fetchUnreadCount);

const fetchTicketNotifications = () => {
  store.dispatch('notifications/index', {
    notificationType: TICKET_ACTIVITY_TYPE,
  });
};

const closePopover = () => {
  if (isOpen.value) {
    toggleOpen(false);
  }
};

const onToggle = () => {
  toggleOpen();
  if (isOpen.value) {
    fetchTicketNotifications();
  }
};

const openNotification = async notification => {
  const { id, primaryActorId, primaryActorType } = notification;
  try {
    // Não usar a action genérica `notifications/read`: ela sobrescreve
    // $state.meta.unreadCount (contagem de TODAS as notificações, usada pelo
    // badge de Inbox da sidebar) com o valor passado - 1. Como aqui só temos
    // a contagem específica de ticket_activity, isso corromperia o badge
    // genérico. Chamamos a API direto e só atualizamos o registro local;
    // `unreadCount` é recalculado pelo watch acima a partir do backend.
    await NotificationsAPI.read(primaryActorType, primaryActorId);
    store.commit(`notifications/${types.READ_NOTIFICATION}`, {
      id,
      read_at: new Date(),
    });
  } catch (error) {
    // proceed to navigation regardless
  }

  closePopover();
  router.push({ name: 'ticket_show', params: { ticketId: primaryActorId } });
};

onMounted(fetchUnreadCount);
</script>

<template>
  <div v-on-click-outside="closePopover" class="relative">
    <Button
      icon="i-lucide-bell"
      color="slate"
      size="sm"
      class="relative flex-shrink-0 dark:hover:!bg-n-slate-9/30 !h-7 !w-8 !outline-n-weak !text-n-slate-11"
      :class="{ '!bg-n-alpha-2 dark:!bg-n-slate-9/30': isOpen }"
      :title="t('TICKET_NOTIFICATIONS.TOOLTIP')"
      @click="onToggle()"
    >
      <SidebarUnreadBadge
        :count="unreadCount"
        class="absolute -top-1.5 ltr:-right-1.5 rtl:-left-1.5 !h-4 !min-w-4 !text-[0.625rem]"
      />
    </Button>
    <div
      v-show="isOpen"
      class="absolute z-40 ltr:left-0 rtl:right-0 top-full mt-2 w-72 max-h-96 overflow-y-auto rounded-lg bg-n-solid-2 outline outline-1 outline-n-weak shadow-lg"
    >
      <ul
        v-if="ticketNotifications.length"
        class="flex flex-col m-0 list-none divide-y divide-n-weak"
      >
        <li v-for="notification in ticketNotifications" :key="notification.id">
          <button
            class="w-full text-left rtl:text-right px-3 py-2 hover:bg-n-alpha-1 dark:hover:bg-n-alpha-3"
            :class="{ 'bg-n-alpha-1 dark:bg-n-alpha-3': !notification.readAt }"
            @click="openNotification(notification)"
          >
            <p class="m-0 text-sm font-medium text-n-slate-12 truncate">
              {{ notification.pushMessageTitle }}
            </p>
            <p class="m-0 text-xs text-n-slate-11 truncate">
              {{ notification.pushMessageBody }}
            </p>
          </button>
        </li>
      </ul>
      <p v-else class="p-4 text-sm text-center text-n-slate-10">
        {{ t('TICKET_NOTIFICATIONS.EMPTY_STATE') }}
      </p>
    </div>
  </div>
</template>
