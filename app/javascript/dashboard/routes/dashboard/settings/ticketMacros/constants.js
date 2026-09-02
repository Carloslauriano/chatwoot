export const TICKET_MACRO_ACTION_TYPES = [
  {
    key: 'change_ticket_status',
    label: 'CHANGE_TICKET_STATUS',
    inputType: 'search_select',
  },
  {
    key: 'assign_team',
    label: 'ASSIGN_TEAM',
    inputType: 'search_select',
  },
  {
    key: 'add_label',
    label: 'ADD_LABEL',
    inputType: 'multi_select',
  },
  {
    key: 'remove_label',
    label: 'REMOVE_LABEL',
    inputType: 'multi_select',
  },
  {
    key: 'change_priority',
    label: 'CHANGE_PRIORITY',
    inputType: 'search_select',
  },
  {
    key: 'archive_ticket',
    label: 'ARCHIVE_TICKET',
    inputType: null,
  },
  {
    key: 'unarchive_ticket',
    label: 'UNARCHIVE_TICKET',
    inputType: null,
  },
];

export const TICKET_PRIORITY_OPTIONS = ['baixa', 'media', 'alta', 'critica'];

export const emptyTicketMacro = {
  name: '',
  actions: [
    {
      action_name: 'assign_team',
      action_params: [],
    },
  ],
};
