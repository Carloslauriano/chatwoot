<script setup>
import { computed, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import NextButton from 'dashboard/components-next/button/Button.vue';
import EmptyState from '../../../../components/widgets/EmptyState.vue';

const { t } = useI18n();
const route = useRoute();
const store = useStore();

const teams = useMapGetter('teams/getTeams');
const team = computed(() =>
  teams.value.find(item => String(item.id) === route.params.teamId)
);

const onToggleDefaultForTickets = async event => {
  try {
    await store.dispatch('teams/update', {
      id: route.params.teamId,
      default_for_tickets: event.target.checked,
    });
  } catch (error) {
    useAlert(t('TEAMS_SETTINGS.FINISH.DEFAULT_FOR_TICKETS_UPDATE_ERROR'));
  }
};

onMounted(() => {
  if (!teams.value.length) store.dispatch('teams/get');
});
</script>

<template>
  <div class="h-full w-full p-6 col-span-6">
    <EmptyState
      :title="$t('TEAMS_SETTINGS.FINISH.TITLE')"
      :message="$t('TEAMS_SETTINGS.FINISH.MESSAGE')"
      :button-text="$t('TEAMS_SETTINGS.FINISH.BUTTON_TEXT')"
    >
      <div v-if="team" class="flex items-center justify-center gap-2 mb-4">
        <input
          id="default_for_tickets"
          type="checkbox"
          :checked="team.default_for_tickets"
          @change="onToggleDefaultForTickets"
        />
        <label for="default_for_tickets">
          {{ $t('TEAMS_SETTINGS.FINISH.DEFAULT_FOR_TICKETS_LABEL') }}
        </label>
      </div>
      <div class="w-full text-center">
        <router-link
          :to="{
            name: 'settings_teams_list',
          }"
        >
          <NextButton teal :label="$t('TEAMS_SETTINGS.FINISH.BUTTON_TEXT')" />
        </router-link>
      </div>
    </EmptyState>
  </div>
</template>
