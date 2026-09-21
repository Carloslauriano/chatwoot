import { nextTick } from 'vue';
import LinkPreviewsAPI from 'dashboard/api/linkPreviews';

// Compartilhado entre descrição e comentários de ticket — mesma URL não
// precisa ser buscada duas vezes.
const linkTitleCache = new Map();

export const domainFor = href => {
  try {
    return new URL(href).hostname.replace(/^www\./, '');
  } catch (error) {
    return href;
  }
};

// Links "crus" (colados sem texto próprio) mostram o domínio de cara e
// trocam pelo <title> da página assim que a busca no backend termina —
// igual o preview de link do Trello. Nunca mexe em link com texto próprio
// (ex: [texto](url) do markdown).
export function useLinkPreviewEnrichment() {
  const enrichLinks = async containerEl => {
    await nextTick();
    if (!containerEl) return;

    // Compara com o atributo cru (getAttribute), não com anchor.href: o
    // navegador normaliza anchor.href (ex: adiciona "/" em domínio sem path),
    // o que faz um link "cru" sem path nunca bater com o texto original.
    const bareLinkAnchors = Array.from(
      containerEl.querySelectorAll('a[href]')
    ).filter(
      anchor => anchor.textContent.trim() === anchor.getAttribute('href')
    );

    bareLinkAnchors.forEach(async anchor => {
      const href = anchor.getAttribute('href');
      anchor.title = href;
      anchor.textContent = domainFor(href);

      if (linkTitleCache.has(href)) {
        anchor.textContent = linkTitleCache.get(href) || domainFor(href);
        return;
      }

      try {
        const { data } = await LinkPreviewsAPI.fetchTitle(href);
        linkTitleCache.set(href, data?.title || null);
        if (data?.title) anchor.textContent = data.title;
      } catch (error) {
        linkTitleCache.set(href, null);
      }
    });
  };

  return { enrichLinks };
}
