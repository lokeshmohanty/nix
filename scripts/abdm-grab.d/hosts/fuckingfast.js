'use strict';
/*
 * Host: fuckingfast.co
 *
 * Landing pages look like https://fuckingfast.co/<id>#<filename>; the fragment
 * is only a label the paste author attached and never reaches the server.
 *
 * The page is htmx-driven. The DOWNLOAD button is:
 *
 *   <a hx-post="/f/<id>/go"
 *      hx-trigger="click[!!window.turnstileToken || !!window.dlCleared]"
 *      hx-vals='js:{"cf-turnstile-response": window.turnstileToken}'>
 *
 * so the direct link comes from POST /f/<id>/go, which requires either a
 * Cloudflare Turnstile token or an already-cleared session. The page says as
 * much: "First click - open ads. Second - start download" -- the first click
 * fires the ad popunder, the second passes the trigger guard.
 *
 * Two separate Cloudflare mechanisms are in play, and both matter:
 *   - the site sits behind a managed challenge, so fetching the page at all
 *     needs a browser TLS fingerprint (see lib/impersonate.js) plus a
 *     cf_clearance cookie;
 *   - the download itself needs a Turnstile token, unless the session already
 *     carries the `dlpass` cookie that solving it once sets.
 */

const { URL } = require('url');
const { result, isChallenge, isDead, downloadHeaders, looksLikeFile } = require('./common');
const impersonate = require('../lib/impersonate');

const HOST = 'fuckingfast.co';

/** The file id is the first path segment. */
function fileId(link) {
  try {
    return new URL(link).pathname.split('/').filter(Boolean)[0] || '';
  } catch (e) {
    return '';
  }
}

/** Size shown on the page: "Size: 2.0GB | Downloads: 2216". */
const SIZE_UNITS = { B: 1, KB: 1024, MB: 1024 ** 2, GB: 1024 ** 3, TB: 1024 ** 4 };
function parseSize(html) {
  const m = html.match(/Size:\s*([\d.]+)\s*([KMGT]?B)/i);
  if (!m) return null;
  const n = parseFloat(m[1]);
  const unit = SIZE_UNITS[m[2].toUpperCase()];
  return n && unit ? Math.round(n * unit) : null;
}

/** The direct URL, wherever the /go response chooses to put it. */
function findDirect(res, body) {
  const header = res.headers['hx-redirect'] || res.headers['location'];
  if (header && /^https?:\/\//i.test(header)) return header;
  const patterns = [
    /window\.open\(\s*["']([^"']+)["']/i,
    /["'](?:url|link|download)["']\s*:\s*["'](https?:\/\/[^"']+)["']/i,
    /href\s*=\s*["'](https?:\/\/[^"']*\/dl\/[^"']+)["']/i,
    /(https?:\/\/[^\s"'<>]+\/dl\/[^\s"'<>]+)/i,
  ];
  for (const re of patterns) {
    const m = (body || '').match(re);
    if (m) return m[1];
  }
  const trimmed = (body || '').trim();
  if (/^https?:\/\/\S+$/.test(trimmed)) return trimmed;   // bare URL response
  return null;
}

module.exports = {
  name: 'fuckingfast',
  description: 'fuckingfast.co (needs curl-impersonate; Turnstile unless the session is cleared)',

  match(url, parsed) {
    return /(^|\.)fuckingfast\.co$/i.test(parsed.hostname);
  },

  async resolve(link, ctx) {
    const id = fileId(link);
    if (!id) return result.error(link, 'could not find a file id in the URL');

    const headers = downloadHeaders(ctx, HOST, link);
    const cookie = headers.Cookie || '';

    // Node cannot get past the managed challenge regardless of cookies, so this
    // host is resolvable only through the impersonating transport.
    if (!impersonate.available()) {
      impersonate.warnMissing(HOST);
      return {
        status: 'challenge', kind: 'transport', url: link,
        note: 'needs curl-impersonate (Cloudflare fingerprints the TLS handshake)',
      };
    }

    let page;
    try {
      page = impersonate.text(link, {
        headers: { Cookie: cookie, Referer: 'https://' + HOST + '/' },
        timeout: 30000,
      });
    } catch (e) {
      return result.error(link, 'fetch failed: ' + e.message);
    }

    if (isChallenge(page, page.text)) return result.challenge(link, HOST);
    if (page.status === 404 || isDead(page.text)) return result.dead(link);
    if (page.status !== 200) {
      return result.error(link, 'unexpected HTTP ' + page.status + ' from ' + HOST);
    }

    const size = parseSize(page.text);
    // /go mints a signed dl.fuckingfast.co URL that stays valid for minutes,
    // not hours (verified: reusable immediately, 404 several minutes later).
    // The CLI uses this to push the user towards starting the queue at once.
    const ephemeral = true;
    const endpoint = (page.text.match(/hx-post="([^"]+)"/) || [, '/f/' + id + '/go'])[1];
    const meta = { headers, downloadPage: link, size, ephemeral };

    // Occasionally the link is already in the page; take it if so.
    const inPage = findDirect({ headers: {} }, page.text);
    if (inPage && looksLikeFile(inPage)) return result.direct(inPage, meta);

    let go;
    try {
      go = impersonate.request(new URL(endpoint, link).toString(), {
        method: 'POST',
        headers: {
          Cookie: cookie,
          Referer: link,
          'HX-Request': 'true',
          'HX-Current-URL': link,
        },
        followRedirects: false,
        timeout: 30000,
      });
    } catch (e) {
      return result.error(link, '/go request failed: ' + e.message);
    }

    const body = go.body.toString('utf8');
    if (/captcha verification failed/i.test(body) || go.status === 403) {
      return Object.assign({
        status: 'challenge',
        kind: 'captcha',
        url: link,
        note: 'fuckingfast wants a Turnstile token; solve one download in Chrome ' +
              'to set the dlpass cookie, then re-run',
      }, meta);
    }

    const direct = findDirect(go, body);
    if (direct) return result.direct(direct, meta);

    return Object.assign(result.passthrough(
      link, `/go returned HTTP ${go.status} with no download link`
    ), meta);
  },
};
