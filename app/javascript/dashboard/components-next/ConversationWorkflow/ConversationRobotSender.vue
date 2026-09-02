<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import NextButton from 'dashboard/components-next/button/Button.vue';
import SingleSelect from 'dashboard/components-next/filter/inputs/SingleSelect.vue';

const { t } = useI18n();
const { currentAccount, updateAccount } = useAccount();

const agents = useMapGetter('agents/getAgents');

const agentOptions = computed(() =>
  agents.value?.length
    ? agents.value.map(agent => ({ id: agent.id, name: agent.name }))
    : []
);

const robotSenderAgent = ref(null);
const isSubmitting = ref(false);

const savedSettings = computed(() => currentAccount.value?.settings || {});

const selectedRobotSenderUserId = computed(
  () => robotSenderAgent.value?.id ?? null
);

watch(
  [savedSettings, agentOptions],
  ([{ robot_sender_user_id } = {}]) => {
    robotSenderAgent.value = agentOptions.value.find(
      option => option.id === robot_sender_user_id
    );
  },
  { deep: true, immediate: true }
);

const hasChanges = computed(() => {
  return (
    selectedRobotSenderUserId.value !==
    (savedSettings.value.robot_sender_user_id || null)
  );
});

const handleSave = async () => {
  try {
    isSubmitting.value = true;
    await updateAccount(
      { robot_sender_user_id: selectedRobotSenderUserId.value },
      { silent: true }
    );
    useAlert(t('CONVERSATION_WORKFLOW.ROBOT_SENDER.SAVE.SUCCESS'));
  } catch (error) {
    useAlert(t('CONVERSATION_WORKFLOW.ROBOT_SENDER.SAVE.ERROR'));
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
        {{ t('CONVERSATION_WORKFLOW.ROBOT_SENDER.TITLE') }}
      </h3>
      <p class="mb-0 text-body-para text-n-slate-11">
        {{ t('CONVERSATION_WORKFLOW.ROBOT_SENDER.DESCRIPTION') }}
      </p>
    </div>
    <div class="px-5 py-4">
      <div
        class="rounded-xl border border-n-weak bg-n-solid-1 w-full text-sm text-n-slate-12"
      >
        <div class="p-3 h-12 flex items-center justify-between">
          <span>
            {{ t('CONVERSATION_WORKFLOW.ROBOT_SENDER.LABEL') }}
          </span>
          <div class="flex items-center gap-1">
            <SingleSelect
              v-model="robotSenderAgent"
              :options="agentOptions"
              :placeholder="t('CONVERSATION_WORKFLOW.ROBOT_SENDER.PLACEHOLDER')"
              placeholder-icon="i-lucide-chevron-down"
              placeholder-trailing-icon
              variant="faded"
            />
            <NextButton
              v-if="robotSenderAgent"
              v-tooltip="t('CONVERSATION_WORKFLOW.ROBOT_SENDER.CLEAR')"
              variant="ghost"
              icon="i-lucide-x"
              slate
              @click="robotSenderAgent = null"
            />
          </div>
        </div>
      </div>
      <div class="flex gap-2 mt-4">
        <NextButton
          blue
          :is-loading="isSubmitting"
          :disabled="!hasChanges"
          :label="t('CONVERSATION_WORKFLOW.ROBOT_SENDER.SAVE_BUTTON')"
          @click="handleSave"
        />
      </div>
    </div>
  </div>
</template>
