<script setup>
import { ref } from 'vue';
import AddLabel from 'shared/components/ui/dropdown/AddLabel.vue';
import LabelDropdown from 'shared/components/ui/label/LabelDropdown.vue';
import Label from 'dashboard/components-next/label/Label.vue';
import { colorForLabel } from 'dashboard/helper/ticketCardHelper';

defineProps({
  accountLabels: {
    type: Array,
    default: () => [],
  },
  selectedLabels: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['add', 'remove']);

const showDropdown = ref(false);
const closeDropdown = () => {
  showDropdown.value = false;
};
</script>

<template>
  <div
    v-on-clickaway="closeDropdown"
    class="relative flex flex-wrap items-center gap-1"
  >
    <AddLabel @add="showDropdown = !showDropdown" />
    <Label
      v-for="labelName in selectedLabels"
      :key="labelName"
      :label="labelName"
      :color="colorForLabel(labelName)"
      compact
    />
    <div
      v-show="showDropdown"
      class="absolute z-[100] w-72 p-2 mt-1 border rounded-lg shadow-lg top-full bg-n-alpha-3 backdrop-blur-[100px] border-n-strong"
    >
      <LabelDropdown
        v-if="showDropdown"
        :account-labels="accountLabels"
        :selected-labels="selectedLabels"
        :allow-creation="false"
        @add="label => emit('add', label)"
        @remove="title => emit('remove', title)"
      />
    </div>
  </div>
</template>
