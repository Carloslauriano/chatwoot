# Troca link "cru" (colado sem texto próprio, com ou sem <>) por
# [título](url) no texto ANTES de salvar — assim a tela só renderiza markdown
# normal, sem precisar de uma requisição a cada abertura (LinkPreviewService
# já cacheia por 1h, então o custo do fetch só existe uma vez, aqui).
# Links que já têm texto próprio (ex: [texto](url)) nunca são tocados.
class LinkTextEnricherService
  AUTOLINK_REGEX = %r{<(https?://[^\s<>]+)>}
  BARE_URL_REGEX = %r{(?<!\()(?<!<)https?://[^\s<>()]+}

  def self.enrich(text)
    new(text).enrich
  end

  def initialize(text)
    @text = text.to_s
  end

  def enrich
    with_autolinks_replaced = @text.gsub(AUTOLINK_REGEX) { replace(Regexp.last_match(1), Regexp.last_match(0)) }
    with_autolinks_replaced.gsub(BARE_URL_REGEX) { |url| replace(url, url) }
  end

  private

  def replace(url, original)
    title = LinkPreviewService.fetch(url)
    title.present? ? "[#{title}](#{url})" : original
  end
end
