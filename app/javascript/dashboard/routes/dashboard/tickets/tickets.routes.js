import { frontendURL } from 'dashboard/helper/URLHelper.js';

import TicketsIndex from './pages/TicketsIndex.vue';
import TicketsKanban from './pages/TicketsKanban.vue';
import TicketShow from './pages/TicketShow.vue';

const meta = {
  permissions: ['administrator', 'agent'],
};

const ticketsRoutes = {
  routes: [
    {
      path: frontendURL('accounts/:accountId/tickets'),
      children: [
        {
          path: '',
          name: 'tickets_index',
          meta,
          component: TicketsIndex,
        },
        {
          path: 'kanban',
          name: 'tickets_kanban',
          meta,
          component: TicketsKanban,
        },
        {
          path: ':ticketId',
          name: 'ticket_show',
          meta,
          component: TicketShow,
        },
      ],
    },
  ],
};

export default ticketsRoutes;
