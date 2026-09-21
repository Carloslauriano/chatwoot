# Busca o <title>/og:title de uma URL pra exibir no lugar do link cru na
# descrição do ticket (igual o Trello faz com links colados). Usa SafeFetch
# (mesma proteção contra SSRF do resto do app) e cacheia o resultado — inclusive
# falha — pra não reprocessar a mesma URL a cada abertura do card.
class LinkPreviewService
  CACHE_TTL = 1.hour
  MAX_BYTES = 512.kilobytes
  TITLE_MAX_LENGTH = 200

  def self.fetch(url)
    new(url).fetch
  end

  def initialize(url)
    @url = url.to_s
  end

  def fetch
    Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) { fetch_title }
  end

  private

  attr_reader :url

  def cache_key
    "link_preview_service/title/#{Digest::SHA256.hexdigest(url)}"
  end

  def fetch_title
    extract_title(fetch_document)
  rescue SafeFetch::Error => e
    Rails.logger.info "[LinkPreviewService] failed to fetch #{url}: #{e.class} - #{e.message}"
    nil
  end

  def fetch_document
    body = nil
    SafeFetch.fetch(
      url,
      max_bytes: MAX_BYTES,
      allowed_content_type_prefixes: [],
      allowed_content_types: %w[text/html application/xhtml+xml]
    ) { |result| body = result.tempfile.read }

    Nokogiri::HTML(body)
  end

  def extract_title(doc)
    og_title = doc.at_css('meta[property="og:title"]')&.[]('content')
    raw_title = og_title.presence || doc.at_xpath('//title')&.text

    raw_title&.squish&.truncate(TITLE_MAX_LENGTH).presence
  end
end
