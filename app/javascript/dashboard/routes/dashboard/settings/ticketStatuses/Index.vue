<script setup>
import { computed, onMounted, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';

const { t } = useI18n();
const store = useStore();

const ticketStatuses = useMapGetter('ticketStatuses/getTicketStatuses');
const uiFlags = useMapGetter('ticketStatuses/getUIFlags');
const teams = useMapGetter('teams/getTeams');

const showModal = ref(false);
const editingId = ref(null);
const showDeletePopup = ref(false);
const deletingStatus = ref({});

// teamPositions: { [teamId]: position } — só os times marcados aparecem
// aqui; a posição de cada um sobrepõe formState.position quando o Kanban
// filtra por aquele time específico.
const formState = reactive({
  name: '',
  position: 0,
  isDefault: false,
  teamPositions: {},
});

const resetForm = () => {
  formState.name = '';
  formState.position = ticketStatuses.value.length;
  formState.isDefault = false;
  formState.teamPositions = {};
  editingId.value = null;
};

const openCreateModal = () => {
  resetForm();
  showModal.value = true;
};

const openEditModal = ticketStatus => {
  editingId.value = ticketStatus.id;
  formState.name = ticketStatus.name;
  formState.position = ticketStatus.position || 0;
  formState.isDefault = ticketStatus.is_default || false;
  formState.teamPositions = Object.fromEntries(
    (ticketStatus.team_positions || []).map(tp => [tp.team_id, tp.position])
  );
  showModal.value = true;
};

const isTeamSelected = id => id in formState.teamPositions;

const toggleTeam = id => {
  if (isTeamSelected(id)) {
    delete formState.teamPositions[id];
  } else {
    formState.teamPositions[id] = formState.position;
  }
};

const teamNames = ticketStatus =>
  (ticketStatus.team_ids || [])
    .map(id => teams.value.find(team => team.id === id)?.name)
    .filter(Boolean)
    .join(', ') || t('TICKET_STATUSES_SETTINGS.ALL_TEAMS');

const isSubmitDisabled = computed(() => !formState.name.trim());

const submit = async () => {
  if (isSubmitDisabled.value) return;
  const payload = {
    name: formState.name.trim(),
    position: Number(formState.position) || 0,
    is_default: formState.isDefault,
    team_positions: Object.entries(formState.teamPositions).map(
      ([teamId, position]) => ({
        team_id: Number(teamId),
        position: Number(position) || 0,
      })
    ),
  };
  try {
    if (editingId.value) {
      await store.dispatch('ticketStatuses/update', {
        id: editingId.value,
        ...payload,
      });
    } else {
      await store.dispatch('ticketStatuses/create', payload);
    }
    // Marcar um status como padrão pode ter desmarcado outro no backend —
    // recarrega a lista pra refletir isso sem precisar de lógica local.
    await store.dispatch('ticketStatuses/get');
    useAlert(t('TICKET_STATUSES_SETTINGS.FORM.SUCCESS'));
    showModal.value = false;
  } catch (error) {
    useAlert(t('TICKET_STATUSES_SETTINGS.FORM.ERROR'));
  }
};

const openDelete = ticketStatus => {
  deletingStatus.value = ticketStatus;
  showDeletePopup.value = true;
};

const confirmDeletePlaceHolder = computed(() =>
  t('TICKET_STATUSES_SETTINGS.DELETE.PLACE_HOLDER', {
    statusName: deletingStatus.value.name,
  })
);

const confirmDelete = async () => {
  try {
    await store.dispatch('ticketStatuses/delete', deletingStatus.value.id);
    useAlert(t('TICKET_STATUSES_SETTINGS.DELETE.SUCCESS'));
  } catch (error) {
    useAlert(t('TICKET_STATUSES_SETTINGS.DELETE.ERROR'));
  } finally {
    showDeletePopup.value = false;
  }
};

onMounted(() => {
  store.dispatch('ticketStatuses/get');
  store.dispatch('teams/get');
});
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="t('TICKET_STATUSES_SETTINGS.LOADING')"
    :no-records-found="!ticketStatuses.length"
    :no-records-message="t('TICKET_STATUSES_SETTINGS.EMPTY')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="t('TICKET_STATUSES_SETTINGS.HEADER')"
        :description="t('TICKET_STATUSES_SETTINGS.DESCRIPTION')"
      >
        <template #actions>
          <Button
            :label="t('TICKET_STATUSES_SETTINGS.NEW_BUTTON')"
            size="sm"
            @click="openCreateModal"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <div class="divide-y divide-n-weak border-t border-n-weak">
        <div
          v-for="ticketStatus in ticketStatuses"
          :key="ticketStatus.id"
          class="flex items-center justify-between gap-4 py-4"
        >
          <div class="flex flex-col gap-1">
            <span
              class="flex items-center gap-2 text-heading-3 text-n-slate-12"
            >
              {{ ticketStatus.name }}
              <span
                v-if="ticketStatus.is_default"
                class="px-1.5 py-0.5 text-xs rounded-md bg-n-blue-3 text-n-blue-11"
              >
                {{ t('TICKET_STATUSES_SETTINGS.DEFAULT_BADGE') }}
              </span>
            </span>
            <span class="text-body-main text-n-slate-11">
              {{ t('TICKET_STATUSES_SETTINGS.TEAMS_LABEL') }}:
              {{ teamNames(ticketStatus) }}
            </span>
          </div>
          <div class="flex gap-2">
            <Button
              icon="i-woot-settings"
              slate
              sm
              @click="openEditModal(ticketStatus)"
            />
            <Button
              icon="i-woot-bin"
              slate
              sm
              class="hover:enabled:text-n-ruby-11 hover:enabled:bg-n-ruby-2"
              @click="openDelete(ticketStatus)"
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
              ? t('TICKET_STATUSES_SETTINGS.FORM.EDIT_TITLE')
              : t('TICKET_STATUSES_SETTINGS.FORM.NEW_TITLE')
          }}
        </h3>

        <woot-input
          v-model="formState.name"
          :label="t('TICKET_STATUSES_SETTINGS.FORM.NAME_LABEL')"
          :placeholder="t('TICKET_STATUSES_SETTINGS.FORM.NAME_PLACEHOLDER')"
        />

        <woot-input
          v-model="formState.position"
          type="number"
          :label="t('TICKET_STATUSES_SETTINGS.FORM.POSITION_LABEL')"
        />

        <div class="flex flex-col gap-1">
          <span class="text-sm font-medium text-n-slate-12">
            {{ t('TICKET_STATUSES_SETTINGS.FORM.TEAMS_LABEL') }}
          </span>
          <p class="text-xs text-n-slate-11">
            {{ t('TICKET_STATUSES_SETTINGS.FORM.TEAMS_HELP') }}
          </p>
          <p class="text-xs text-n-slate-11">
            {{ t('TICKET_STATUSES_SETTINGS.FORM.TEAM_POSITION_HELP') }}
          </p>
          <div
            v-if="teams.length"
            class="flex flex-col overflow-y-auto border rounded-lg border-n-weak max-h-64"
          >
            <div
              v-for="team in teams"
              :key="team.id"
              class="flex items-center gap-2 px-3 py-2 text-sm hover:bg-n-alpha-1"
            >
              <label class="flex items-center flex-1 gap-2 cursor-pointer">
                <Checkbox
                  :model-value="isTeamSelected(team.id)"
                  @update:model-value="toggleTeam(team.id)"
                />
                <span class="truncate text-n-slate-12">{{ team.name }}</span>
              </label>
              <input
                v-if="isTeamSelected(team.id)"
                v-model.number="formState.teamPositions[team.id]"
                type="number"
                class="w-16 text-xs rounded-md border border-n-weak"
                :placeholder="
                  t('TICKET_STATUSES_SETTINGS.FORM.TEAM_POSITION_PLACEHOLDER')
                "
              />
            </div>
          </div>
          <p v-else class="text-xs text-n-slate-11">
            {{ t('TICKET_STATUSES_SETTINGS.FORM.NO_TEAMS') }}
          </p>
        </div>

        <label class="flex items-center gap-2 cursor-pointer">
          <Checkbox
            :model-value="formState.isDefault"
            @update:model-value="value => (formState.isDefault = value)"
          />
          <span class="text-sm text-n-slate-12">
            {{ t('TICKET_STATUSES_SETTINGS.FORM.IS_DEFAULT_LABEL') }}
          </span>
        </label>
        <p class="text-xs text-n-slate-11">
          {{ t('TICKET_STATUSES_SETTINGS.FORM.IS_DEFAULT_HELP') }}
        </p>

        <div class="flex items-center justify-end gap-2 mt-2">
          <Button
            faded
            slate
            :label="t('TICKET_STATUSES_SETTINGS.FORM.CANCEL')"
            @click="showModal = false"
          />
          <Button
            :label="t('TICKET_STATUSES_SETTINGS.FORM.SUBMIT')"
            :disabled="isSubmitDisabled"
            @click="submit"
          />
        </div>
      </div>
    </woot-modal>

    <woot-confirm-delete-modal
      v-if="showDeletePopup"
      v-model:show="showDeletePopup"
      :title="t('TICKET_STATUSES_SETTINGS.DELETE.TITLE')"
      :message="t('TICKET_STATUSES_SETTINGS.DELETE.MESSAGE')"
      :confirm-text="t('TICKET_STATUSES_SETTINGS.DELETE.CONFIRM')"
      :reject-text="t('TICKET_STATUSES_SETTINGS.DELETE.CANCEL')"
      :confirm-value="deletingStatus.name"
      :confirm-place-holder-text="confirmDeletePlaceHolder"
      @on-confirm="confirmDelete"
      @on-close="showDeletePopup = false"
    />
  </SettingsLayout>
</template>
