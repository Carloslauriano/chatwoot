<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import Switch from 'next/switch/Switch.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();
const { currentAccount, updateAccount } = useAccount();

const requirePriorityBeforeAssignment = ref(false);
const requireTeamFullyPrioritizedBeforeAssignment = ref(false);
const isSubmitting = ref(false);

const savedSettings = computed(() => currentAccount.value?.settings || {});

watch(
  savedSettings,
  ({
    require_priority_before_assignment,
    require_team_fully_prioritized_before_assignment,
  } = {}) => {
    requirePriorityBeforeAssignment.value =
      !!require_priority_before_assignment;
    requireTeamFullyPrioritizedBeforeAssignment.value =
      !!require_team_fully_prioritized_before_assignment;
  },
  { deep: true, immediate: true }
);

const hasChanges = computed(() => {
  return (
    requirePriorityBeforeAssignment.value !==
      !!savedSettings.value.require_priority_before_assignment ||
    requireTeamFullyPrioritizedBeforeAssignment.value !==
      !!savedSettings.value.require_team_fully_prioritized_before_assignment
  );
});

const handleSave = async () => {
  try {
    isSubmitting.value = true;
    await updateAccount(
      {
        require_priority_before_assignment:
          requirePriorityBeforeAssignment.value,
        require_team_fully_prioritized_before_assignment:
          requirePriorityBeforeAssignment.value &&
          requireTeamFullyPrioritizedBeforeAssignment.value,
      },
      { silent: true }
    );
    useAlert(
      t('CONVERSATION_WORKFLOW.PRIORITY_GATING_ASSIGNMENT.SAVE.SUCCESS')
    );
  } catch (error) {
    useAlert(t('CONVERSATION_WORKFLOW.PRIORITY_GATING_ASSIGNMENT.SAVE.ERROR'));
  } finally {
    isSubmitting.value = false;
  }
};
</script>

<template>
  <div
    class="flex flex-col w-full outline-1 outline outline-n-container rounded-xl bg-n-solid-2 divide-y divide-n-weak"
  >
    <div class="flex flex-col gap-2 items-start px-5 py-4">
      <h3 class="text-heading-2 text-n-slate-12">
        {{ t('CONVERSATION_WORKFLOW.PRIORITY_GATING_ASSIGNMENT.TITLE') }}
      </h3>
      <p class="mb-0 text-body-para text-n-slate-11">
        {{ t('CONVERSATION_WORKFLOW.PRIORITY_GATING_ASSIGNMENT.DESCRIPTION') }}
      </p>
    </div>
    <div class="px-5 py-4">
      <div
        class="rounded-xl border border-n-weak bg-n-solid-1 w-full text-sm text-n-slate-12 divide-y divide-n-weak"
      >
        <div class="p-3 h-12 flex items-center justify-between">
          <span>
            {{
              t(
                'CONVERSATION_WORKFLOW.PRIORITY_GATING_ASSIGNMENT.REQUIRE_PRIORITY.LABEL'
              )
            }}
          </span>
          <Switch v-model="requirePriorityBeforeAssignment" />
        </div>
        <div
          v-if="requirePriorityBeforeAssignment"
          class="p-3 h-12 flex items-center justify-between"
        >
          <span>
            {{
              t(
                'CONVERSATION_WORKFLOW.PRIORITY_GATING_ASSIGNMENT.REQUIRE_TEAM_FULLY_PRIORITIZED.LABEL'
              )
            }}
          </span>
          <Switch v-model="requireTeamFullyPrioritizedBeforeAssignment" />
        </div>
      </div>
      <div class="flex gap-2 mt-4">
        <NextButton
          blue
          :is-loading="isSubmitting"
          :disabled="!hasChanges"
          :label="
            t('CONVERSATION_WORKFLOW.PRIORITY_GATING_ASSIGNMENT.SAVE_BUTTON')
          "
          @click="handleSave"
        />
      </div>
    </div>
  </div>
</template>
