'use strict';
/*
 * Source: any web page (the fallback when no other source matches).
 *
 * Collects <a href> targets plus bare http(s)/magnet URLs in the body text, so
 * it works on both link-list pages and plain-text dumps.
 */

const { extractFromHtml } = require('../lib/extract');

module.exports = {
  name: 'html',
  description: 'generic web page or text file (anchors + bare URLs)',

  match() { return true; },   // always last in the registry

  async extract(url, ctx) {
    const res = await ctx.http.text(url, {
      accept: 'text/html,application/xhtml+xml,text/plain,*/*',
      timeout: 30000,
      maxBytes: 16 * 1024 * 1024,
    });

    const contentType = (res.headers['content-type'] || '').toLowerCase();
    const links = extractFromHtml(res.text, res.url);

    // A direct file URL: nothing to scrape, the URL is itself the download.
    if (!links.length && contentType && !/text\/html|xhtml|text\/plain/.test(contentType)) {
      return { title: null, links: [url], pageUrl: url };
    }

    const m = res.text.match(/<title[^>]*>([^<]*)<\/title>/i);
    return {
      title: m ? m[1].trim() : null,
      links,
      pageUrl: res.url,
    };
  },
};
