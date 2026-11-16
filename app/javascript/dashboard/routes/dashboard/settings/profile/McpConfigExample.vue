<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  token: { type: String, default: '' },
  disabled: { type: Boolean, default: false },
});

const { t } = useI18n();
const { accountId } = useAccount();

const MASK = '••••••••••••••••';
const revealed = ref(false);

const serverUrl = computed(
  () => `${window.location.origin}/api/v1/accounts/${accountId.value}/mcp`
);

const buildSnippets = token => [
  {
    key: 'CLAUDE_CODE',
    text: `claude mcp add --transport http chatwoot-tickets ${serverUrl.value} \\\n  --header "api_access_token: ${token}"`,
  },
  {
    key: 'JSON_CONFIG',
    text: JSON.stringify(
      {
        mcpServers: {
          'chatwoot-tickets': {
            command: 'npx',
            args: [
              '-y',
              'mcp-remote',
              serverUrl.value,
              '--header',
              `api_access_token:${token}`,
            ],
          },
        },
      },
      null,
      2
    ),
  },
];

const shown = computed(() =>
  buildSnippets(revealed.value ? props.token : MASK)
);
const real = computed(() => buildSnippets(props.token));

const toggleReveal = () => {
  revealed.value = !revealed.value;
};

const copy = async index => {
  if (props.disabled) return;
  await copyTextToClipboard(real.value[index].text);
  useAlert(t('PROFILE_SETTINGS.FORM.MCP_CONFIG.COPY_SUCCESS'));
};
</script>

<template>
  <div class="flex flex-col gap-4" data-testid="mcp-config-example">
    <p class="mb-0 text-sm text-n-slate-11">
      {{ t('PROFILE_SETTINGS.FORM.MCP_CONFIG.TOOLS_NOTE') }}
    </p>
    <div class="flex flex-col gap-1">
      <span class="text-sm font-medium text-n-slate-12">
        {{ t('PROFILE_SETTINGS.FORM.MCP_CONFIG.SERVER_URL') }}
      </span>
      <code
        class="px-3 py-2 text-xs break-all rounded-xl bg-n-alpha-2 text-n-slate-12"
        data-testid="mcp-server-url"
      >
        {{ serverUrl }}
      </code>
    </div>
    <div
      v-for="(snippet, index) in shown"
      :key="snippet.key"
      class="flex flex-col gap-1"
    >
      <div class="flex items-center justify-between gap-2">
        <span class="text-sm font-medium text-n-slate-12">
          {{ t(`PROFILE_SETTINGS.FORM.MCP_CONFIG.${snippet.key}`) }}
        </span>
        <div class="flex gap-2">
          <NextButton
            v-if="index === 0"
            slate
            outline
            type="button"
            size="sm"
            :icon="revealed ? 'i-lucide-eye-off' : 'i-lucide-eye'"
            :label="
              revealed
                ? t('PROFILE_SETTINGS.FORM.MCP_CONFIG.HIDE_TOKEN')
                : t('PROFILE_SETTINGS.FORM.MCP_CONFIG.SHOW_TOKEN')
            "
            :disabled="disabled"
            @click="toggleReveal"
          />
          <NextButton
            slate
            outline
            type="button"
            size="sm"
            icon="i-lucide-copy"
            :label="t('PROFILE_SETTINGS.FORM.MCP_CONFIG.COPY')"
            :disabled="disabled"
            :data-testid="`mcp-copy-${snippet.key}`"
            @click="copy(index)"
          />
        </div>
      </div>
      <pre
        class="p-3 m-0 overflow-x-auto text-xs whitespace-pre-wrap break-all rounded-xl bg-n-alpha-2 text-n-slate-12"
        :data-testid="`mcp-snippet-${snippet.key}`"
        >{{ snippet.text }}</pre
      >
    </div>
  </div>
</template>
