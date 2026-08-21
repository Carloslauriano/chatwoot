<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import CreateTicket from './CreateTicket.vue';
import LinkTicket from './LinkTicket.vue';

defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const emit = defineEmits(['close']);
const { t } = useI18n();

const selectedTabIndex = ref(0);

const tabs = ref([
  { key: 0, name: t('TICKETS.CREATE_OR_LINK.TABS.CREATE') },
  { key: 1, name: t('TICKETS.CREATE_OR_LINK.TABS.LINK') },
]);

const onClose = () => emit('close');
const onClickTabChange = index => {
  selectedTabIndex.value = index;
};
</script>

<template>
  <div class="flex flex-col h-auto overflow-auto">
    <woot-modal-header
      :header-title="$t('TICKETS.CREATE_OR_LINK.TITLE')"
      :header-content="$t('TICKETS.CREATE_OR_LINK.DESCRIPTION')"
    />

    <div class="flex flex-col h-auto overflow-auto">
      <div class="flex flex-col px-8 pb-4 mt-1">
        <woot-tabs
          class="ltr:[&>ul]:pl-0 rtl:[&>ul]:pr-0 h-10"
          :index="selectedTabIndex"
          @change="onClickTabChange"
        >
          <woot-tabs-item
            v-for="(tab, index) in tabs"
            :key="tab.key"
            :index="index"
            :name="tab.name"
            :show-badge="false"
            is-compact
          />
        </woot-tabs>
      </div>

      <div v-if="selectedTabIndex === 0" class="flex flex-col px-8 pb-4">
        <CreateTicket
          :conversation-id="conversationId"
          @close="onClose"
          @created="onClose"
        />
      </div>
      <div v-else class="flex flex-col px-8 pb-4">
        <LinkTicket
          :conversation-id="conversationId"
          @close="onClose"
          @linked="onClose"
        />
      </div>
    </div>
  </div>
</template>
