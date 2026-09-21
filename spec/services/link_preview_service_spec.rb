require 'rails_helper'

RSpec.describe LinkPreviewService do
  let(:url) { 'https://example.com/article' }

  before do
    allow(Resolv).to receive(:getaddresses).and_call_original
    allow(Resolv).to receive(:getaddresses).with('example.com').and_return(['93.184.216.34'])
  end

  describe '.fetch' do
    it 'returns the og:title when present, even if a <title> tag also exists' do
      stub_request(:get, url).to_return(
        status: 200,
        body: '<html><head><title>Fallback Title</title><meta property="og:title" content="Real Page Title" /></head></html>',
        headers: { 'content-type' => 'text/html' }
      )

      expect(described_class.fetch(url)).to eq('Real Page Title')
    end

    it 'falls back to the <title> tag when og:title is missing' do
      stub_request(:get, url).to_return(
        status: 200,
        body: '<html><head><title>Plain Title</title></head></html>',
        headers: { 'content-type' => 'text/html' }
      )

      expect(described_class.fetch(url)).to eq('Plain Title')
    end

    it 'returns nil when the page has no title' do
      stub_request(:get, url).to_return(status: 200, body: '<html><head></head></html>', headers: { 'content-type' => 'text/html' })

      expect(described_class.fetch(url)).to be_nil
    end

    it 'returns nil when the request fails' do
      stub_request(:get, url).to_return(status: 500)

      expect(described_class.fetch(url)).to be_nil
    end

    it 'returns nil for a non-http(s) url instead of raising' do
      expect(described_class.fetch('javascript:alert(1)')).to be_nil
    end

    it 'caches the result so a second call does not hit the network again' do
      # Test env uses a null store; swap in a real store so caching behaviour is observable.
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
      request_stub = stub_request(:get, url).to_return(
        status: 200,
        body: '<html><head><title>Cached Title</title></head></html>',
        headers: { 'content-type' => 'text/html' }
      )

      described_class.fetch(url)
      described_class.fetch(url)

      expect(request_stub).to have_been_requested.once
    end
  end
end
