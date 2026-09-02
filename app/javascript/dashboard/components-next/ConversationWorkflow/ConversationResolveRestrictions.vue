<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import Switch from 'next/switch/Switch.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();
const { currentAccount, updateAccount } = useAccount();

const requireLabelBeforeResolve = ref(false);
const requirePriorityBeforeResolve = ref(false);
const requireAssigneeBeforeResolve = ref(false);
const disableSnooze = ref(false);
const disablePending = ref(false);
const isSubmitting = ref(false);

const savedSettings = computed(() => currentAccount.value?.settings || {});

watch(
  savedSettings,
  ({
    require_label_before_resolve,
    require_priority_before_resolve,
    require_assignee_before_resolve,
    disable_snooze,
    disable_pending,
  } = {}) => {
    requireLabelBeforeResolve.value = !!require_label_before_resolve;
    requirePriorityBeforeResolve.value = !!require_priority_before_resolve;
    requireAssigneeBeforeResolve.value = !!require_assignee_before_resolve;
    disableSnooze.value = !!disable_snooze;
    disablePending.value = !!disable_pending;
  },
  { deep: true, immediate: true }
);

const hasChanges = computed(() => {
  return (
    requireLabelBeforeResolve.value !==
      !!savedSettings.value.require_label_before_resolve ||
    requirePriorityBeforeResolve.value !==
      !!savedSettings.value.require_priority_before_resolve ||
    requireAssigneeBeforeResolve.value !==
      !!savedSettings.value.require_assignee_before_resolve ||
    disableSnooze.value !== !!savedSettings.value.disable_snooze ||
    disablePending.value !== !!savedSettings.value.disable_pending
  );
});

const handleSave = async () => {
  try {
    isSubmitting.value = true;
    await updateAccount(
      {
        require_label_before_resolve: requireLabelBeforeResolve.value,
        require_priority_before_resolve: requirePriorityBeforeResolve.value,
        require_assignee_before_resolve: requireAssigneeBeforeResolve.value,
        disable_snooze: disableSnooze.value,
        disable_pending: disablePending.value,
      },
      { silent: true }
    );
    useAlert(t('CONVERSATION_WORKFLOW.RESOLVE_RESTRICTIONS.SAVE.SUCCESS'));
  } catch (error) {
    useAlert(t('CONVERSATION_WORKFLOW.RESOLVE_RESTRICTIONS.SAVE.ERROR'));
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
        {{ t('CONVERSATION_WORKFLOW.RESOLVE_RESTRICTIONS.TITLE') }}
      </h3>
      <p class="mb-0 text-body-para text-n-slate-11">
        {{ t('CONVERSATION_WORKFLOW.RESOLVE_RESTRICTIONS.DESCRIPTION') }}
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
                'CONVERSATION_WORKFLOW.RESOLVE_RESTRICTIONS.REQUIRE_LABEL.LABEL'
              )
            }}
          </span>
          <Switch v-model="requireLabelBeforeResolve" />
        </div>
        <div class="p-3 h-12 flex items-center justify-between">
          <span>
            {{
              t(
                'CONVERSATION_WORKFLOW.RESOLVE_RESTRICTIONS.REQUIRE_PRIORITY.LABEL'
              )
            }}
          </span>
          <Switch v-model="requirePriorityBeforeResolve" />
        </div>
        <div class="p-3 h-12 flex items-center justify-between">
          <span>
            {{
              t(
                'CONVERSATION_WORKFLOW.RESOLVE_RESTRICTIONS.REQUIRE_ASSIGNEE.LABEL'
              )
            }}
          </span>
          <Switch v-model="requireAssigneeBeforeResolve" />
        </div>
      </div>
      <div class="flex flex-col gap-2 mt-4">
        <h4 class="text-xs font-medium uppercase tracking-wide text-n-slate-10">
          {{
            t('CONVERSATION_WORKFLOW.RESOLVE_RESTRICTIONS.STATUS_ACTIONS.TITLE')
          }}
        </h4>
        <div
          class="rounded-xl border border-n-weak bg-n-solid-1 w-full text-sm text-n-slate-12 divide-y divide-n-weak"
        >
          <div class="p-3 h-12 flex items-center justify-between">
            <span>
              {{
                t(
                  'CONVERSATION_WORKFLOW.RESOLVE_RESTRICTIONS.DISABLE_SNOOZE.LABEL'
                )
              }}
            </span>
            <Switch v-model="disableSnooze" />
          </div>
          <div class="p-3 h-12 flex items-center justify-between">
            <span>
              {{
                t(
                  'CONVERSATION_WORKFLOW.RESOLVE_RESTRICTIONS.DISABLE_PENDING.LABEL'
                )
              }}
            </span>
            <Switch v-model="disablePending" />
          </div>
        </div>
      </div>
      <div class="flex gap-2 mt-4">
        <NextButton
          blue
          :is-loading="isSubmitting"
          :disabled="!hasChanges"
          :label="t('CONVERSATION_WORKFLOW.RESOLVE_RESTRICTIONS.SAVE_BUTTON')"
          @click="handleSave"
        />
      </div>
    </div>
  </div>
</template>
