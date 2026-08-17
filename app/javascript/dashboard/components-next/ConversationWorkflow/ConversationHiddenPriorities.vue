<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import Switch from 'next/switch/Switch.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();
const { currentAccount, updateAccount } = useAccount();

const PRIORITIES = ['urgent', 'high', 'medium', 'low'];

const hiddenUrgent = ref(false);
const hiddenHigh = ref(false);
const hiddenMedium = ref(false);
const hiddenLow = ref(false);

const priorityRefs = {
  urgent: hiddenUrgent,
  high: hiddenHigh,
  medium: hiddenMedium,
  low: hiddenLow,
};

const savedHiddenPriorities = computed(
  () => currentAccount.value?.settings?.hidden_priorities || []
);

watch(
  savedHiddenPriorities,
  hidden => {
    PRIORITIES.forEach(priority => {
      priorityRefs[priority].value = hidden.includes(priority);
    });
  },
  { deep: true, immediate: true }
);

const selectedHiddenPriorities = computed(() =>
  PRIORITIES.filter(priority => priorityRefs[priority].value)
);

const hasChanges = computed(() => {
  const current = selectedHiddenPriorities.value;
  const saved = savedHiddenPriorities.value;
  return (
    current.length !== saved.length ||
    current.some(priority => !saved.includes(priority))
  );
});

const isSubmitting = ref(false);

const handleSave = async () => {
  try {
    isSubmitting.value = true;
    await updateAccount(
      { hidden_priorities: selectedHiddenPriorities.value },
      { silent: true }
    );
    useAlert(t('CONVERSATION_WORKFLOW.HIDDEN_PRIORITIES.SAVE.SUCCESS'));
  } catch (error) {
    useAlert(t('CONVERSATION_WORKFLOW.HIDDEN_PRIORITIES.SAVE.ERROR'));
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
        {{ t('CONVERSATION_WORKFLOW.HIDDEN_PRIORITIES.TITLE') }}
      </h3>
      <p class="mb-0 text-body-para text-n-slate-11">
        {{ t('CONVERSATION_WORKFLOW.HIDDEN_PRIORITIES.DESCRIPTION') }}
      </p>
    </div>
    <div class="px-5 py-4">
      <div
        class="rounded-xl border border-n-weak bg-n-solid-1 w-full text-sm text-n-slate-12 divide-y divide-n-weak"
      >
        <div class="p-3 h-12 flex items-center justify-between">
          <span>
            {{ t('CONVERSATION_WORKFLOW.HIDDEN_PRIORITIES.URGENT.LABEL') }}
          </span>
          <Switch v-model="hiddenUrgent" />
        </div>
        <div class="p-3 h-12 flex items-center justify-between">
          <span>
            {{ t('CONVERSATION_WORKFLOW.HIDDEN_PRIORITIES.HIGH.LABEL') }}
          </span>
          <Switch v-model="hiddenHigh" />
        </div>
        <div class="p-3 h-12 flex items-center justify-between">
          <span>
            {{ t('CONVERSATION_WORKFLOW.HIDDEN_PRIORITIES.MEDIUM.LABEL') }}
          </span>
          <Switch v-model="hiddenMedium" />
        </div>
        <div class="p-3 h-12 flex items-center justify-between">
          <span>
            {{ t('CONVERSATION_WORKFLOW.HIDDEN_PRIORITIES.LOW.LABEL') }}
          </span>
          <Switch v-model="hiddenLow" />
        </div>
      </div>
      <div class="flex gap-2 mt-4">
        <NextButton
          blue
          :is-loading="isSubmitting"
          :disabled="!hasChanges"
          :label="t('CONVERSATION_WORKFLOW.HIDDEN_PRIORITIES.SAVE_BUTTON')"
          @click="handleSave"
        />
      </div>
    </div>
  </div>
</template>
