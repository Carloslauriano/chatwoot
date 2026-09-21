/* global axios */

import ApiClient from './ApiClient';

class LinkPreviewsAPI extends ApiClient {
  constructor() {
    super('link_previews', { accountScoped: true });
  }

  fetchTitle(url) {
    return axios.post(this.url, { url });
  }
}

export default new LinkPreviewsAPI();
