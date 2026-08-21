<script setup>
import { computed, onMounted, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useAgentsList } from 'dashboard/composables/useAgentsList';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';

const { t } = useI18n();
const store = useStore();

const rules = useMapGetter('ticketAutomationRules/getTicketAutomationRules');
const uiFlags = useMapGetter('ticketAutomationRules/getUIFlags');
const ticketStatuses = useMapGetter('ticketStatuses/getTicketStatuses');
const teams = useMapGetter('teams/getTeams');
const accountLabels = useMapGetter('labels/getLabels');
const { agentsList } = useAgentsList(false);

const showModal = ref(false);
const editingId = ref(null);
const showDeletePopup = ref(false);
const deletingRule = ref({});

// actions: [{ action_name, ticket_status_id, team_id, label, responsavel_id }]
const formState = reactive({
  name: '',
  description: '',
  eventName: 'ticket_status_changed',
  active: true,
  conditions: {
    to_ticket_status_id: '',
    label: '',
    team_id: '',
    ticket_status_id: '',
  },
  actions: [],
});

const EVENT_OPTIONS = [
  { id: 'ticket_status_changed', name: 'STATUS_CHANGED' },
  { id: 'ticket_label_added', name: 'LABEL_ADDED' },
];

const ACTION_OPTIONS = [
  { id: 'change_status', name: 'CHANGE_STATUS' },
  { id: 'transfer_team', name: 'TRANSFER_TEAM' },
  { id: 'add_label', name: 'ADD_LABEL' },
  { id: 'assign_responsible', name: 'ASSIGN_RESPONSIBLE' },
];

const resetForm = () => {
  formState.name = '';
  formState.description = '';
  formState.eventName = 'ticket_status_changed';
  formState.active = true;
  formState.conditions = {
    to_ticket_status_id: '',
    label: '',
    team_id: '',
    ticket_status_id: '',
  };
  formState.actions = [];
  editingId.value = null;
};

const openCreateModal = () => {
  resetForm();
  showModal.value = true;
};

const openEditModal = rule => {
  editingId.value = rule.id;
  formState.name = rule.name;
  formState.description = rule.description || '';
  formState.eventName = rule.event_name;
  formState.active = rule.active;
  formState.conditions = {
    to_ticket_status_id: rule.conditions?.to_ticket_status_id || '',
    label: rule.conditions?.label || '',
    team_id: rule.conditions?.team_id || '',
    ticket_status_id: rule.conditions?.ticket_status_id || '',
  };
  formState.actions = (rule.actions || []).map(action => ({ ...action }));
  showModal.value = true;
};

const addAction = () => {
  formState.actions.push({ action_name: 'change_status' });
};

const removeAction = index => {
  formState.actions.splice(index, 1);
};

const isSubmitDisabled = computed(() => {
  if (!formState.name.trim()) return true;
  if (formState.eventName === 'ticket_status_changed') {
    return !formState.conditions.to_ticket_status_id;
  }
  return !formState.conditions.label.trim();
});

const eventLabel = eventName =>
  t(
    `TICKET_AUTOMATION_RULES_SETTINGS.EVENTS.${EVENT_OPTIONS.find(e => e.id === eventName)?.name}`
  );

const actionLabel = actionName =>
  t(
    `TICKET_AUTOMATION_RULES_SETTINGS.ACTIONS.${ACTION_OPTIONS.find(a => a.id === actionName)?.name}`
  );

const submit = async () => {
  if (isSubmitDisabled.value) return;

  const conditions = {};
  if (formState.eventName === 'ticket_status_changed') {
    conditions.to_ticket_status_id = Number(
      formState.conditions.to_ticket_status_id
    );
  } else {
    conditions.label = formState.conditions.label.trim();
  }
  if (formState.conditions.team_id)
    conditions.team_id = Number(formState.conditions.team_id);
  if (formState.conditions.ticket_status_id) {
    conditions.ticket_status_id = Number(formState.conditions.ticket_status_id);
  }

  const payload = {
    name: formState.name.trim(),
    description: formState.description.trim(),
    event_name: formState.eventName,
    active: formState.active,
    conditions,
    actions: formState.actions,
  };

  try {
    if (editingId.value) {
      await store.dispatch('ticketAutomationRules/update', {
        id: editingId.value,
        ...payload,
      });
    } else {
      await store.dispatch('ticketAutomationRules/create', payload);
    }
    useAlert(t('TICKET_AUTOMATION_RULES_SETTINGS.FORM.SUCCESS'));
    showModal.value = false;
  } catch (error) {
    useAlert(t('TICKET_AUTOMATION_RULES_SETTINGS.FORM.ERROR'));
  }
};

const toggleActive = async rule => {
  try {
    await store.dispatch('ticketAutomationRules/update', {
      id: rule.id,
      active: !rule.active,
    });
  } catch (error) {
    useAlert(t('TICKET_AUTOMATION_RULES_SETTINGS.FORM.ERROR'));
  }
};

const openDelete = rule => {
  deletingRule.value = rule;
  showDeletePopup.value = true;
};

const confirmDeletePlaceHolder = computed(() =>
  t('TICKET_AUTOMATION_RULES_SETTINGS.DELETE.PLACE_HOLDER', {
    ruleName: deletingRule.value.name,
  })
);

const confirmDelete = async () => {
  try {
    await store.dispatch('ticketAutomationRules/delete', deletingRule.value.id);
    useAlert(t('TICKET_AUTOMATION_RULES_SETTINGS.DELETE.SUCCESS'));
  } catch (error) {
    useAlert(t('TICKET_AUTOMATION_RULES_SETTINGS.DELETE.ERROR'));
  } finally {
    showDeletePopup.value = false;
  }
};

onMounted(() => {
  store.dispatch('ticketAutomationRules/get');
  if (!ticketStatuses.value.length) store.dispatch('ticketStatuses/get');
  if (!teams.value.length) store.dispatch('teams/get');
  if (!accountLabels.value?.length) store.dispatch('labels/get');
});
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="t('TICKET_AUTOMATION_RULES_SETTINGS.LOADING')"
    :no-records-found="!rules.length"
    :no-records-message="t('TICKET_AUTOMATION_RULES_SETTINGS.EMPTY')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="t('TICKET_AUTOMATION_RULES_SETTINGS.HEADER')"
        :description="t('TICKET_AUTOMATION_RULES_SETTINGS.DESCRIPTION')"
      >
        <template #actions>
          <Button
            :label="t('TICKET_AUTOMATION_RULES_SETTINGS.NEW_BUTTON')"
            size="sm"
            @click="openCreateModal"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <div class="divide-y divide-n-weak border-t border-n-weak">
        <div
          v-for="rule in rules"
          :key="rule.id"
          class="flex items-center justify-between gap-4 py-4"
        >
          <div class="flex flex-col gap-1">
            <span class="text-heading-3 text-n-slate-12">{{ rule.name }}</span>
            <span class="text-body-main text-n-slate-11">
              {{ eventLabel(rule.event_name) }}
              <span v-if="rule.description"> — {{ rule.description }}</span>
            </span>
            <span
              v-if="(rule.actions || []).length"
              class="text-xs text-n-slate-10"
            >
              {{
                (rule.actions || [])
                  .map(action => actionLabel(action.action_name))
                  .join(', ')
              }}
            </span>
          </div>
          <div class="flex items-center gap-3">
            <label class="flex items-center gap-2 cursor-pointer">
              <Checkbox
                :model-value="rule.active"
                @update:model-value="() => toggleActive(rule)"
              />
              <span class="text-xs text-n-slate-11">
                {{ t('TICKET_AUTOMATION_RULES_SETTINGS.ACTIVE_LABEL') }}
              </span>
            </label>
            <Button
              icon="i-woot-settings"
              slate
              sm
              @click="openEditModal(rule)"
            />
            <Button
              icon="i-woot-bin"
              slate
              sm
              class="hover:enabled:text-n-ruby-11 hover:enabled:bg-n-ruby-2"
              @click="openDelete(rule)"
            />
          </div>
        </div>
      </div>
    </template>

    <woot-modal v-model:show="showModal" :on-close="() => (showModal = false)">
      <div class="flex flex-col gap-4 p-6 overflow-y-auto max-h-[80vh]">
        <h3 class="text-lg font-medium text-n-slate-12">
          {{
            editingId
              ? t('TICKET_AUTOMATION_RULES_SETTINGS.FORM.EDIT_TITLE')
              : t('TICKET_AUTOMATION_RULES_SETTINGS.FORM.NEW_TITLE')
          }}
        </h3>

        <woot-input
          v-model="formState.name"
          :label="t('TICKET_AUTOMATION_RULES_SETTINGS.FORM.NAME_LABEL')"
          :placeholder="
            t('TICKET_AUTOMATION_RULES_SETTINGS.FORM.NAME_PLACEHOLDER')
          "
        />

        <woot-input
          v-model="formState.description"
          :label="t('TICKET_AUTOMATION_RULES_SETTINGS.FORM.DESCRIPTION_LABEL')"
        />

        <label class="flex flex-col gap-1">
          <span class="text-sm font-medium text-n-slate-12">
            {{ t('TICKET_AUTOMATION_RULES_SETTINGS.FORM.EVENT_LABEL') }}
          </span>
          <select
            v-model="formState.eventName"
            class="text-sm rounded-lg border border-n-weak"
          >
            <option
              v-for="event in EVENT_OPTIONS"
              :key="event.id"
              :value="event.id"
            >
              {{ t(`TICKET_AUTOMATION_RULES_SETTINGS.EVENTS.${event.name}`) }}
            </option>
          </select>
        </label>

        <!-- Condições -->
        <div class="flex flex-col gap-3 p-3 border rounded-lg border-n-weak">
          <span class="text-sm font-medium text-n-slate-12">
            {{ t('TICKET_AUTOMATION_RULES_SETTINGS.FORM.CONDITIONS_TITLE') }}
          </span>

          <label
            v-if="formState.eventName === 'ticket_status_changed'"
            class="flex flex-col gap-1"
          >
            <span class="text-xs text-n-slate-11">
              {{ t('TICKET_AUTOMATION_RULES_SETTINGS.FORM.TO_STATUS_LABEL') }}
            </span>
            <select
              v-model="formState.conditions.to_ticket_status_id"
              class="text-sm rounded-lg border border-n-weak"
            >
              <option value="">
                {{
                  t('TICKET_AUTOMATION_RULES_SETTINGS.FORM.SELECT_PLACEHOLDER')
                }}
              </option>
              <option
                v-for="status in ticketStatuses"
                :key="status.id"
                :value="status.id"
              >
                {{ status.name }}
              </option>
            </select>
          </label>

          <label v-else class="flex flex-col gap-1">
            <span class="text-xs text-n-slate-11">
              {{ t('TICKET_AUTOMATION_RULES_SETTINGS.FORM.LABEL_ADDED_LABEL') }}
            </span>
            <select
              v-model="formState.conditions.label"
              class="text-sm rounded-lg border border-n-weak"
            >
              <option value="">
                {{
                  t('TICKET_AUTOMATION_RULES_SETTINGS.FORM.SELECT_PLACEHOLDER')
                }}
              </option>
              <option
                v-for="labelOption in accountLabels"
                :key="labelOption.id"
                :value="labelOption.title"
              >
                {{ labelOption.title }}
              </option>
            </select>
          </label>

          <label
            v-if="formState.eventName === 'ticket_label_added'"
            class="flex flex-col gap-1"
          >
            <span class="text-xs text-n-slate-11">
              {{
                t('TICKET_AUTOMATION_RULES_SETTINGS.FORM.CURRENT_STATUS_LABEL')
              }}
            </span>
            <select
              v-model="formState.conditions.ticket_status_id"
              class="text-sm rounded-lg border border-n-weak"
            >
              <option value="">
                {{ t('TICKET_AUTOMATION_RULES_SETTINGS.FORM.ANY_OPTION') }}
              </option>
              <option
                v-for="status in ticketStatuses"
                :key="status.id"
                :value="status.id"
              >
                {{ status.name }}
              </option>
            </select>
          </label>

          <label class="flex flex-col gap-1">
            <span class="text-xs text-n-slate-11">
              {{
                t('TICKET_AUTOMATION_RULES_SETTINGS.FORM.CURRENT_TEAM_LABEL')
              }}
            </span>
            <select
              v-model="formState.conditions.team_id"
              class="text-sm rounded-lg border border-n-weak"
            >
              <option value="">
                {{ t('TICKET_AUTOMATION_RULES_SETTINGS.FORM.ANY_OPTION') }}
              </option>
              <option v-for="team in teams" :key="team.id" :value="team.id">
                {{ team.name }}
              </option>
            </select>
          </label>
        </div>

        <!-- Ações -->
        <div class="flex flex-col gap-3 p-3 border rounded-lg border-n-weak">
          <span class="text-sm font-medium text-n-slate-12">
            {{ t('TICKET_AUTOMATION_RULES_SETTINGS.FORM.ACTIONS_TITLE') }}
          </span>

          <div
            v-for="(action, index) in formState.actions"
            :key="index"
            class="flex items-end gap-2"
          >
            <label class="flex flex-col flex-1 gap-1">
              <span class="text-xs text-n-slate-11">
                {{ t('TICKET_AUTOMATION_RULES_SETTINGS.FORM.ACTION_LABEL') }}
              </span>
              <select
                v-model="action.action_name"
                class="text-sm rounded-lg border border-n-weak"
              >
                <option
                  v-for="option in ACTION_OPTIONS"
                  :key="option.id"
                  :value="option.id"
                >
                  {{
                    t(`TICKET_AUTOMATION_RULES_SETTINGS.ACTIONS.${option.name}`)
                  }}
                </option>
              </select>
            </label>

            <label
              v-if="action.action_name === 'change_status'"
              class="flex flex-col flex-1 gap-1"
            >
              <span class="text-xs text-n-slate-11">
                {{
                  t('TICKET_AUTOMATION_RULES_SETTINGS.FORM.STATUS_VALUE_LABEL')
                }}
              </span>
              <select
                v-model="action.ticket_status_id"
                class="text-sm rounded-lg border border-n-weak"
              >
                <option
                  v-for="status in ticketStatuses"
                  :key="status.id"
                  :value="status.id"
                >
                  {{ status.name }}
                </option>
              </select>
            </label>

            <label
              v-else-if="action.action_name === 'transfer_team'"
              class="flex flex-col flex-1 gap-1"
            >
              <span class="text-xs text-n-slate-11">
                {{
                  t('TICKET_AUTOMATION_RULES_SETTINGS.FORM.TEAM_VALUE_LABEL')
                }}
              </span>
              <select
                v-model="action.team_id"
                class="text-sm rounded-lg border border-n-weak"
              >
                <option v-for="team in teams" :key="team.id" :value="team.id">
                  {{ team.name }}
                </option>
              </select>
            </label>

            <label
              v-else-if="action.action_name === 'add_label'"
              class="flex flex-col flex-1 gap-1"
            >
              <span class="text-xs text-n-slate-11">
                {{
                  t('TICKET_AUTOMATION_RULES_SETTINGS.FORM.LABEL_VALUE_LABEL')
                }}
              </span>
              <select
                v-model="action.label"
                class="text-sm rounded-lg border border-n-weak"
              >
                <option
                  v-for="labelOption in accountLabels"
                  :key="labelOption.id"
                  :value="labelOption.title"
                >
                  {{ labelOption.title }}
                </option>
              </select>
            </label>

            <label
              v-else-if="action.action_name === 'assign_responsible'"
              class="flex flex-col flex-1 gap-1"
            >
              <span class="text-xs text-n-slate-11">
                {{
                  t(
                    'TICKET_AUTOMATION_RULES_SETTINGS.FORM.RESPONSIBLE_VALUE_LABEL'
                  )
                }}
              </span>
              <select
                v-model="action.responsavel_id"
                class="text-sm rounded-lg border border-n-weak"
              >
                <option
                  v-for="agent in agentsList"
                  :key="agent.id"
                  :value="agent.id"
                >
                  {{ agent.name }}
                </option>
              </select>
            </label>

            <Button
              icon="i-lucide-x"
              slate
              faded
              sm
              @click="removeAction(index)"
            />
          </div>

          <Button
            icon="i-lucide-plus"
            slate
            faded
            size="small"
            :label="t('TICKET_AUTOMATION_RULES_SETTINGS.FORM.ADD_ACTION')"
            class="w-fit"
            @click="addAction"
          />
        </div>

        <label class="flex items-center gap-2 cursor-pointer">
          <Checkbox
            :model-value="formState.active"
            @update:model-value="value => (formState.active = value)"
          />
          <span class="text-sm text-n-slate-12">
            {{ t('TICKET_AUTOMATION_RULES_SETTINGS.FORM.ACTIVE_LABEL') }}
          </span>
        </label>

        <div class="flex items-center justify-end gap-2 mt-2">
          <Button
            faded
            slate
            :label="t('TICKET_AUTOMATION_RULES_SETTINGS.FORM.CANCEL')"
            @click="showModal = false"
          />
          <Button
            :label="t('TICKET_AUTOMATION_RULES_SETTINGS.FORM.SUBMIT')"
            :disabled="isSubmitDisabled"
            @click="submit"
          />
        </div>
      </div>
    </woot-modal>

    <woot-confirm-delete-modal
      v-if="showDeletePopup"
      v-model:show="showDeletePopup"
      :title="t('TICKET_AUTOMATION_RULES_SETTINGS.DELETE.TITLE')"
      :message="t('TICKET_AUTOMATION_RULES_SETTINGS.DELETE.MESSAGE')"
      :confirm-text="t('TICKET_AUTOMATION_RULES_SETTINGS.DELETE.CONFIRM')"
      :reject-text="t('TICKET_AUTOMATION_RULES_SETTINGS.DELETE.CANCEL')"
      :confirm-value="deletingRule.name"
      :confirm-place-holder-text="confirmDeletePlaceHolder"
      @on-confirm="confirmDelete"
      @on-close="showDeletePopup = false"
    />
  </SettingsLayout>
</template>
