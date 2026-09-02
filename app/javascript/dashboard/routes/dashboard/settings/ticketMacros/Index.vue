<script setup>
import { computed, onMounted, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import AutomationActionInput from 'dashboard/components/widgets/AutomationActionInput.vue';
import {
  generateTeamOptions,
  generateLabelOptions,
} from 'dashboard/helper/automationHelper';
import generatePayload from 'dashboard/helper/actionQueryGenerator.js';
import {
  TICKET_MACRO_ACTION_TYPES,
  TICKET_PRIORITY_OPTIONS,
  emptyTicketMacro,
} from './constants';

const { t } = useI18n();
const store = useStore();

const ticketMacros = useMapGetter('ticketMacros/getTicketMacros');
const uiFlags = useMapGetter('ticketMacros/getUIFlags');
const teams = useMapGetter('teams/getTeams');
const accountLabels = useMapGetter('labels/getLabels');
const ticketStatuses = useMapGetter('ticketStatuses/getTicketStatuses');

const actionTypes = computed(() =>
  TICKET_MACRO_ACTION_TYPES.map(type => ({
    ...type,
    label: t(`TICKET_MACROS.ACTIONS.${type.label}`),
  }))
);

const getDropdownValues = actionName => {
  switch (actionName) {
    case 'change_ticket_status':
      return ticketStatuses.value.map(status => ({
        id: status.id,
        name: status.name,
      }));
    case 'assign_team':
      return generateTeamOptions(teams.value);
    case 'add_label':
    case 'remove_label':
      return generateLabelOptions(accountLabels.value);
    case 'change_priority':
      return TICKET_PRIORITY_OPTIONS.map(id => ({
        id,
        name: t(`TICKETS.PRIORITY_OPTIONS.${id.toUpperCase()}`),
      }));
    default:
      return [];
  }
};

const resolveActionsSummary = macro =>
  macro.actions
    .map(action => {
      const type = TICKET_MACRO_ACTION_TYPES.find(
        item => item.key === action.action_name
      );
      return type
        ? t(`TICKET_MACROS.ACTIONS.${type.label}`)
        : action.action_name;
    })
    .join(', ');

const showModal = ref(false);
const editingId = ref(null);
const showDeletePopup = ref(false);
const deletingMacro = ref({});

const formState = reactive({
  name: '',
  actions: [],
});

const resetForm = () => {
  formState.name = emptyTicketMacro.name;
  formState.actions = emptyTicketMacro.actions.map(action => ({ ...action }));
  editingId.value = null;
};

const openCreateModal = () => {
  resetForm();
  showModal.value = true;
};

const openEditModal = macro => {
  editingId.value = macro.id;
  formState.name = macro.name;
  formState.actions = macro.actions.map(action => {
    const dropdownValues = getDropdownValues(action.action_name);
    let actionParams = [];
    if (action.action_params?.length) {
      actionParams = dropdownValues.length
        ? dropdownValues.filter(item => action.action_params.includes(item.id))
        : [...action.action_params];
    }
    return { ...action, action_params: actionParams };
  });
  showModal.value = true;
};

const appendNewAction = () => {
  formState.actions.push({
    action_name: TICKET_MACRO_ACTION_TYPES[0].key,
    action_params: [],
  });
};

const removeAction = index => {
  formState.actions.splice(index, 1);
};

const resetAction = index => {
  formState.actions[index] = {
    ...formState.actions[index],
    action_params: [],
  };
};

const isSubmitDisabled = computed(
  () =>
    !formState.name.trim() ||
    !formState.actions.length ||
    formState.actions.some(action => !action.action_name)
);

const submit = async () => {
  if (isSubmitDisabled.value) return;
  const payload = {
    name: formState.name.trim(),
    actions: generatePayload(formState.actions),
  };
  try {
    if (editingId.value) {
      await store.dispatch('ticketMacros/update', {
        id: editingId.value,
        ...payload,
      });
    } else {
      await store.dispatch('ticketMacros/create', payload);
    }
    useAlert(t('TICKET_MACROS.FORM.SUCCESS'));
    showModal.value = false;
  } catch (error) {
    useAlert(t('TICKET_MACROS.FORM.ERROR'));
  }
};

const openDelete = macro => {
  deletingMacro.value = macro;
  showDeletePopup.value = true;
};

const confirmDeletePlaceHolder = computed(() =>
  t('TICKET_MACROS.DELETE.PLACE_HOLDER', {
    macroName: deletingMacro.value.name,
  })
);

const confirmDelete = async () => {
  try {
    await store.dispatch('ticketMacros/delete', deletingMacro.value.id);
    useAlert(t('TICKET_MACROS.DELETE.SUCCESS'));
  } catch (error) {
    useAlert(t('TICKET_MACROS.DELETE.ERROR'));
  } finally {
    showDeletePopup.value = false;
  }
};

onMounted(() => {
  store.dispatch('ticketMacros/get');
  if (!teams.value.length) {
    store.dispatch('teams/get');
  }
  if (!accountLabels.value?.length) {
    store.dispatch('labels/get');
  }
  if (!ticketStatuses.value.length) {
    store.dispatch('ticketStatuses/get');
  }
});
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="t('TICKET_MACROS.LOADING')"
    :no-records-found="!ticketMacros.length"
    :no-records-message="t('TICKET_MACROS.EMPTY')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="t('TICKET_MACROS.HEADER')"
        :description="t('TICKET_MACROS.DESCRIPTION')"
      >
        <template #actions>
          <Button
            :label="t('TICKET_MACROS.NEW_BUTTON')"
            size="sm"
            @click="openCreateModal"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <div class="divide-y divide-n-weak border-t border-n-weak">
        <div
          v-for="macro in ticketMacros"
          :key="macro.id"
          class="flex items-center justify-between gap-4 py-4"
        >
          <div class="flex flex-col gap-1 min-w-0">
            <span class="text-heading-3 text-n-slate-12">
              {{ macro.name }}
            </span>
            <span class="text-body-main text-n-slate-11 truncate">
              {{ resolveActionsSummary(macro) }}
            </span>
          </div>
          <div class="flex gap-2 shrink-0">
            <Button
              icon="i-woot-settings"
              slate
              sm
              @click="openEditModal(macro)"
            />
            <Button
              icon="i-woot-bin"
              slate
              sm
              class="hover:enabled:text-n-ruby-11 hover:enabled:bg-n-ruby-2"
              @click="openDelete(macro)"
            />
          </div>
        </div>
      </div>
    </template>

    <woot-modal v-model:show="showModal" :on-close="() => (showModal = false)">
      <div class="flex flex-col gap-4 p-6">
        <h3 class="text-lg font-medium text-n-slate-12">
          {{
            editingId
              ? t('TICKET_MACROS.FORM.EDIT_TITLE')
              : t('TICKET_MACROS.FORM.NEW_TITLE')
          }}
        </h3>

        <woot-input
          v-model="formState.name"
          :label="t('TICKET_MACROS.FORM.NAME_LABEL')"
          :placeholder="t('TICKET_MACROS.FORM.NAME_PLACEHOLDER')"
        />

        <div class="flex flex-col gap-1">
          <span class="text-sm font-medium text-n-slate-12">
            {{ t('TICKET_MACROS.FORM.ACTIONS_LABEL') }}
          </span>
          <ul
            class="grid p-3 list-none border-solid outline outline-1 rounded-xl -outline-offset-1 outline-n-weak dark:outline-n-strong"
          >
            <AutomationActionInput
              v-for="(action, index) in formState.actions"
              :key="index"
              v-model="formState.actions[index]"
              :action-types="actionTypes"
              :dropdown-values="getDropdownValues(action.action_name)"
              @reset-action="resetAction(index)"
              @remove-action="removeAction(index)"
            />
            <div class="pt-2">
              <Button
                icon="i-lucide-plus"
                blue
                faded
                sm
                :label="t('TICKET_MACROS.FORM.ADD_ACTION_BUTTON')"
                @click="appendNewAction"
              />
            </div>
          </ul>
        </div>

        <div class="flex items-center justify-end gap-2 mt-2">
          <Button
            faded
            slate
            :label="t('TICKET_MACROS.FORM.CANCEL')"
            @click="showModal = false"
          />
          <Button
            :label="t('TICKET_MACROS.FORM.SUBMIT')"
            :disabled="isSubmitDisabled"
            @click="submit"
          />
        </div>
      </div>
    </woot-modal>

    <woot-confirm-delete-modal
      v-if="showDeletePopup"
      v-model:show="showDeletePopup"
      :title="t('TICKET_MACROS.DELETE.TITLE')"
      :message="t('TICKET_MACROS.DELETE.MESSAGE')"
      :confirm-text="t('TICKET_MACROS.DELETE.CONFIRM')"
      :reject-text="t('TICKET_MACROS.DELETE.CANCEL')"
      :confirm-value="deletingMacro.name"
      :confirm-place-holder-text="confirmDeletePlaceHolder"
      @on-confirm="confirmDelete"
      @on-close="showDeletePopup = false"
    />
  </SettingsLayout>
</template>
