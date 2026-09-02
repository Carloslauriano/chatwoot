<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import Switch from 'next/switch/Switch.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();
const { currentAccount, updateAccount } = useAccount();

const autoAssignOnAgentReply = ref(false);
const isSubmitting = ref(false);

const savedSettings = computed(() => currentAccount.value?.settings || {});

watch(
  savedSettings,
  ({ auto_assign_on_agent_reply } = {}) => {
    autoAssignOnAgentReply.value = !!auto_assign_on_agent_reply;
  },
  { deep: true, immediate: true }
);

const hasChanges = computed(() => {
  return (
    autoAssignOnAgentReply.value !==
    !!savedSettings.value.auto_assign_on_agent_reply
  );
});

const handleSave = async () => {
  try {
    isSubmitting.value = true;
    await updateAccount(
      { auto_assign_on_agent_reply: autoAssignOnAgentReply.value },
      { silent: true }
    );
    useAlert(t('CONVERSATION_WORKFLOW.AUTO_ASSIGN_ON_REPLY.SAVE.SUCCESS'));
  } catch (error) {
    useAlert(t('CONVERSATION_WORKFLOW.AUTO_ASSIGN_ON_REPLY.SAVE.ERROR'));
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
      <div class="flex justify-between items-center w-full">
        <h3 class="text-heading-2 text-n-slate-12">
          {{ t('CONVERSATION_WORKFLOW.AUTO_ASSIGN_ON_REPLY.TITLE') }}
        </h3>
        <Switch v-model="autoAssignOnAgentReply" />
      </div>
      <p class="mb-0 text-body-para text-n-slate-11">
        {{ t('CONVERSATION_WORKFLOW.AUTO_ASSIGN_ON_REPLY.DESCRIPTION') }}
      </p>
    </div>
    <div class="px-5 py-4">
      <div class="flex gap-2">
        <NextButton
          blue
          :is-loading="isSubmitting"
          :disabled="!hasChanges"
          :label="t('CONVERSATION_WORKFLOW.AUTO_ASSIGN_ON_REPLY.SAVE_BUTTON')"
          @click="handleSave"
        />
      </div>
    </div>
  </div>
</template>
