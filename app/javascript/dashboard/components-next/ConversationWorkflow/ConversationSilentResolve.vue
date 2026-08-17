<script setup>
import { h, ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import Switch from 'next/switch/Switch.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import SingleSelect from 'dashboard/components-next/filter/inputs/SingleSelect.vue';

const { t } = useI18n();
const { currentAccount, updateAccount } = useAccount();

const labels = useMapGetter('labels/getLabels');

const labelOptions = computed(() =>
  labels.value?.length
    ? labels.value.map(label => ({
        id: label.title,
        name: label.title,
        icon: h('span', {
          class: `size-[12px] ring-1 ring-n-alpha-1 dark:ring-white/20 ring-inset rounded-sm`,
          style: { backgroundColor: label.color },
        }),
      }))
    : []
);

const silentResolveEnabled = ref(false);
const labelToApply = ref(null);
const isSubmitting = ref(false);

const savedSettings = computed(() => currentAccount.value?.settings || {});

const selectedLabelName = computed(() => labelToApply.value?.name ?? null);

watch(
  [savedSettings, labelOptions],
  ([{ silent_resolve_enabled, silent_resolve_label } = {}]) => {
    silentResolveEnabled.value = !!silent_resolve_enabled;
    labelToApply.value = labelOptions.value.find(
      option => option.name === silent_resolve_label
    );
  },
  { deep: true, immediate: true }
);

const hasChanges = computed(() => {
  return (
    silentResolveEnabled.value !==
      !!savedSettings.value.silent_resolve_enabled ||
    selectedLabelName.value !==
      (savedSettings.value.silent_resolve_label || null)
  );
});

const handleSave = async () => {
  try {
    isSubmitting.value = true;
    await updateAccount(
      {
        silent_resolve_enabled: silentResolveEnabled.value,
        silent_resolve_label: selectedLabelName.value,
      },
      { silent: true }
    );
    useAlert(t('CONVERSATION_WORKFLOW.SILENT_RESOLVE.SAVE.SUCCESS'));
  } catch (error) {
    useAlert(t('CONVERSATION_WORKFLOW.SILENT_RESOLVE.SAVE.ERROR'));
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
          {{ t('CONVERSATION_WORKFLOW.SILENT_RESOLVE.TITLE') }}
        </h3>
        <Switch v-model="silentResolveEnabled" />
      </div>
      <p class="mb-0 text-body-para text-n-slate-11">
        {{ t('CONVERSATION_WORKFLOW.SILENT_RESOLVE.DESCRIPTION') }}
      </p>
    </div>
    <div v-if="silentResolveEnabled" class="px-5 py-4">
      <div
        class="rounded-xl border border-n-weak bg-n-solid-1 w-full text-sm text-n-slate-12"
      >
        <div class="p-3 h-12 flex items-center justify-between">
          <span>
            {{ t('CONVERSATION_WORKFLOW.SILENT_RESOLVE.LABEL.LABEL') }}
          </span>
          <SingleSelect
            v-model="labelToApply"
            :options="labelOptions"
            :placeholder="
              t('CONVERSATION_WORKFLOW.SILENT_RESOLVE.LABEL.PLACEHOLDER')
            "
            placeholder-icon="i-lucide-chevron-down"
            placeholder-trailing-icon
            variant="faded"
          />
        </div>
      </div>
      <div class="flex gap-2 mt-4">
        <NextButton
          blue
          :is-loading="isSubmitting"
          :disabled="!hasChanges"
          :label="t('CONVERSATION_WORKFLOW.SILENT_RESOLVE.SAVE_BUTTON')"
          @click="handleSave"
        />
      </div>
    </div>
  </div>
</template>
