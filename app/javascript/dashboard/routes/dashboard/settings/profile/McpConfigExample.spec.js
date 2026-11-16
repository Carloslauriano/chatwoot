import { ref } from 'vue';
import { mount, flushPromises } from '@vue/test-utils';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import McpConfigExample from './McpConfigExample.vue';

const mocks = vi.hoisted(() => ({
  copy: vi.fn(),
  alert: vi.fn(),
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));
vi.mock('dashboard/composables', () => ({ useAlert: mocks.alert }));
vi.mock('dashboard/composables/useAccount', () => ({
  useAccount: () => ({ accountId: ref(7) }),
}));
vi.mock('shared/helpers/clipboard', () => ({
  copyTextToClipboard: mocks.copy,
}));

const mountComponent = (props = {}) =>
  mount(McpConfigExample, {
    props: { token: 'secret-token-123', ...props },
    global: { stubs: { NextButton: false } },
  });

describe('McpConfigExample', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('builds the server url from the current account', () => {
    const wrapper = mountComponent();

    expect(wrapper.get('[data-testid="mcp-server-url"]').text()).toBe(
      `${window.location.origin}/api/v1/accounts/7/mcp`
    );
  });

  it('masks the token on screen by default', () => {
    const wrapper = mountComponent();

    expect(wrapper.text()).not.toContain('secret-token-123');
    expect(
      wrapper.get('[data-testid="mcp-snippet-CLAUDE_CODE"]').text()
    ).toContain('••••');
  });

  it('copies the real token even while masked', async () => {
    const wrapper = mountComponent();

    await wrapper.get('[data-testid="mcp-copy-CLAUDE_CODE"]').trigger('click');
    await flushPromises();

    expect(mocks.copy).toHaveBeenCalledTimes(1);
    expect(mocks.copy.mock.calls[0][0]).toContain(
      'api_access_token: secret-token-123'
    );
    expect(mocks.copy.mock.calls[0][0]).toContain('/accounts/7/mcp');
  });

  it('copies valid JSON config', async () => {
    const wrapper = mountComponent();

    await wrapper.get('[data-testid="mcp-copy-JSON_CONFIG"]').trigger('click');
    await flushPromises();

    const config = JSON.parse(mocks.copy.mock.calls[0][0]);
    expect(config.mcpServers['chatwoot-tickets'].args).toContain(
      'api_access_token:secret-token-123'
    );
  });

  it('does not copy when disabled', async () => {
    const wrapper = mountComponent({ disabled: true });

    await wrapper.get('[data-testid="mcp-copy-CLAUDE_CODE"]').trigger('click');

    expect(mocks.copy).not.toHaveBeenCalled();
  });
});
