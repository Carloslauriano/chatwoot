import { useLinkPreviewEnrichment } from '../useLinkPreviewEnrichment';
import LinkPreviewsAPI from 'dashboard/api/linkPreviews';

vi.mock('dashboard/api/linkPreviews', () => ({
  default: { fetchTitle: vi.fn() },
}));

const buildContainer = html => {
  const el = document.createElement('div');
  el.innerHTML = html;
  return el;
};

const flushPromises = () =>
  new Promise(resolve => {
    setTimeout(resolve, 0);
  });

describe('useLinkPreviewEnrichment', () => {
  beforeEach(() => {
    LinkPreviewsAPI.fetchTitle.mockReset();
  });

  it('replaces a bare link with the domain, then the fetched title', async () => {
    LinkPreviewsAPI.fetchTitle.mockResolvedValue({
      data: { title: 'Example Domain' },
    });
    const { enrichLinks } = useLinkPreviewEnrichment();
    const container = buildContainer(
      '<a href="https://www.example.com/path">https://www.example.com/path</a>'
    );

    await enrichLinks(container);
    await flushPromises();

    const anchor = container.querySelector('a');
    expect(anchor.textContent).toBe('Example Domain');
    expect(LinkPreviewsAPI.fetchTitle).toHaveBeenCalledWith(
      'https://www.example.com/path'
    );
  });

  it('does not touch a link that already has its own text', async () => {
    const { enrichLinks } = useLinkPreviewEnrichment();
    const container = buildContainer(
      '<a href="https://example.com">meu link</a>'
    );

    await enrichLinks(container);

    expect(container.querySelector('a').textContent).toBe('meu link');
    expect(LinkPreviewsAPI.fetchTitle).not.toHaveBeenCalled();
  });

  it('falls back to the domain when the title fetch fails', async () => {
    LinkPreviewsAPI.fetchTitle.mockRejectedValue(new Error('network error'));
    const { enrichLinks } = useLinkPreviewEnrichment();
    const container = buildContainer(
      '<a href="https://www.example.com">https://www.example.com</a>'
    );

    await enrichLinks(container);
    await flushPromises();

    expect(container.querySelector('a').textContent).toBe('example.com');
  });

  it('does nothing when the container is null', async () => {
    const { enrichLinks } = useLinkPreviewEnrichment();

    await expect(enrichLinks(null)).resolves.not.toThrow();
  });
});
