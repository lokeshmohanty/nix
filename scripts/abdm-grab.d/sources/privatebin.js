'use strict';
/*
 * Source: PrivateBin pastes (paste.fitgirl-repacks.site and any other instance).
 *
 * Identified by a URL of the form https://host/?<pasteid>#<key>: the paste id is
 * the query string and the decryption key is the fragment, which never reaches
 * the server. Requesting it with `Accept: application/json` returns the
 * encrypted envelope instead of the viewer page.
 */

const privatebin = require('../lib/privatebin');
const { extractUrls } = require('../lib/extract');

module.exports = {
  name: 'privatebin',
  description: 'PrivateBin encrypted paste (decrypted locally with the URL fragment key)',

  match(url, parsed) {
    // A key fragment plus a bare `?id` query is the PrivateBin URL shape. The
    // fragment is base58, so exclude anything containing '=' or '/'.
    const key = parsed.hash.slice(1);
    if (!key || /[=/&]/.test(key)) return false;
    const query = parsed.search.slice(1);
    return !!query && !query.includes('=');
  },

  async extract(url, ctx) {
    const parsed = new URL(url);
    const key = parsed.hash.slice(1);

    const res = await ctx.http.text(url, {
      accept: 'application/json, text/plain, */*',
      headers: { 'X-Requested-With': 'JSONHttpRequest' },
      timeout: 30000,
    });

    let envelope;
    try {
      envelope = JSON.parse(res.text);
    } catch (e) {
      throw new Error(
        'paste did not return JSON (status ' + res.status + ') -- ' +
        'the paste may have expired or been burned after reading'
      );
    }
    if (envelope.status === 1 || envelope.message) {
      throw new Error('PrivateBin: ' + (envelope.message || 'paste unavailable'));
    }
    if (!privatebin.isPaste(envelope)) {
      throw new Error('not a PrivateBin paste envelope (try --source html)');
    }

    const plain = privatebin.decrypt(envelope, key);
    if (!plain.trim()) throw new Error('decrypted paste is empty');

    // PrivateBin v2 wraps the text as {"paste": "..."} plus optional attachment.
    let content = plain;
    let title = null;
    try {
      const inner = JSON.parse(plain);
      if (inner && typeof inner.paste === 'string') content = inner.paste;
      if (inner && typeof inner.attachment_name === 'string') title = inner.attachment_name;
    } catch (e) { /* plain text paste, not JSON-wrapped */ }

    return {
      title,
      links: extractUrls(content),
      // Referer for the eventual downloads: the paste page without its key.
      pageUrl: parsed.origin + parsed.pathname + parsed.search,
    };
  },
};
