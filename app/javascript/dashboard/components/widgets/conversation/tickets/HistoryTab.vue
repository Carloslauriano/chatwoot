<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import TicketsAPI from 'dashboard/api/tickets';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  ticketId: {
    type: [Number, String],
    required: true,
  },
});

const auditLogs = ref([]);
const isLoading = ref(false);
const expandedId = ref(null);

const hasLogs = computed(() => auditLogs.value.length > 0);

const toggleExpand = id => {
  expandedId.value = expandedId.value === id ? null : id;
};

const loadAuditLogs = async () => {
  isLoading.value = true;
  try {
    const response = await TicketsAPI.getAuditLogs(props.ticketId);
    auditLogs.value = response.data || [];
  } catch (error) {
    auditLogs.value = [];
  } finally {
    isLoading.value = false;
  }
};

watch(() => props.ticketId, loadAuditLogs);
onMounted(loadAuditLogs);

defineExpose({ reload: loadAuditLogs });
</script>

<template>
  <div>
    <div v-if="isLoading" class="flex justify-center p-8">
      <Spinner />
    </div>
    <p v-else-if="!hasLogs" class="p-4 text-sm text-n-slate-11">
      {{ $t('TICKETS.HISTORY.EMPTY') }}
    </p>
    <table v-else class="w-full text-sm">
      <thead>
        <tr class="text-left text-n-slate-11">
          <th class="p-2">{{ $t('TICKETS.HISTORY.COLUMNS.WHEN') }}</th>
          <th class="p-2">{{ $t('TICKETS.HISTORY.COLUMNS.WHO') }}</th>
          <th class="p-2">{{ $t('TICKETS.HISTORY.COLUMNS.ACTION') }}</th>
          <th class="p-2" />
        </tr>
      </thead>
      <tbody>
        <template v-for="log in auditLogs" :key="log.id">
          <tr class="border-t border-n-weak">
            <td class="p-2 whitespace-nowrap">{{ log.created_at }}</td>
            <td class="p-2">{{ log.autor_nome || log.autor_id }}</td>
            <td class="p-2">
              {{ log.acao }}
              <span
                v-if="log.editado_manualmente"
                class="ml-1 text-xs text-n-slate-11"
              >
                ({{ $t('TICKETS.HISTORY.EDITED_MANUALLY') }})
              </span>
            </td>
            <td class="p-2 text-right">
              <button
                type="button"
                class="text-xs text-n-slate-11 hover:underline"
                @click="toggleExpand(log.id)"
              >
                {{ $t('TICKETS.HISTORY.VIEW_DETAILS') }}
              </button>
            </td>
          </tr>
          <tr v-if="expandedId === log.id" class="bg-n-alpha-black2">
            <td colspan="4" class="p-2 text-xs">
              <div class="flex gap-4">
                <span>{{ log.campo }}</span>
                <span>
                  {{
                    $t('TICKETS.HISTORY.VALUE_CHANGE', {
                      from: log.valor_antes,
                      to: log.valor_depois,
                    })
                  }}
                </span>
              </div>
            </td>
          </tr>
        </template>
      </tbody>
    </table>
  </div>
</template>
