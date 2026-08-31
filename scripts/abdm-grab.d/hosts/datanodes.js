'use strict';
/*
 * Host: datanodes.to
 *
 * An XFileSharing-derived host, fronted by a Vue app. The flow, established by
 * probing a live file:
 *
 *   1. A plain GET of the landing page answers "File Not Found" even for files
 *      that exist. POST /download with op=download2 is the real entry point.
 *   2. That POST returns the file page, which renders a <download-countdown>
 *      element carrying everything the second step needs: a freshly issued
 *      `rand` token, the countdown length, and whether a captcha is required.
 *   3. Reposting op=download2 with that `rand` after the countdown yields the
 *      direct link -- unless a captcha is demanded, in which case the response
 *      carries message="Wrong captcha".
 *
 * In practice step 3 is gated by a Cloudflare Turnstile widget for free
 * downloads (has-captcha="true"), which cannot be solved outside a browser. The
 * resolver detects that and reports it as a challenge with the file's real name
 * and size, rather than pretending to have resolved anything. The captcha-free
 * path is still implemented because premium sessions and some files skip it.
 */

const { URL } = require('url');
const { result, isChallenge, isDead, downloadHeaders, looksLikeFile } = require('./common');

const HOST = 'datanodes.to';
const ENDPOINT = 'https://' + HOST + '/download';

/** The file id is the first path segment: /q9u4nrgqw2pv/Name.rar */
function parseLink(link) {
  const parsed = new URL(link);
  const segments = parsed.pathname.split('/').filter(Boolean);
  return { id: segments[0] || '', fname: segments[1] ? decodeURIComponent(segments[1]) : '' };
}

/** Attributes of the <download-countdown> element that drives step 3. */
function parseCountdown(html) {
  const m = html.match(/<download-countdown\b([^>]*)>/i);
  if (!m) return null;
  const attrs = {};
  const re = /([:\w-]+)\s*=\s*"([^"]*)"/g;
  let a;
  while ((a = re.exec(m[1])) !== null) attrs[a[1].replace(/^:/, '')] = a[2];
  return attrs;
}

const SIZE_UNITS = { B: 1, KB: 1024, MB: 1024 ** 2, GB: 1024 ** 3, TB: 1024 ** 4 };

/** "2.0 GB" -> bytes. The page states the size in og:title and in the body. */
function parseSize(html) {
  const og = html.match(/property="og:title"\s+content="[^"]*\(([\d.]+)\s*([KMGT]?B)\)"/i);
  const m = og || html.match(/>\s*([\d.]+)\s*([KMGT]B)\s*</);
  if (!m) return null;
  const n = parseFloat(m[1]);
  const unit = SIZE_UNITS[m[2].toUpperCase()];
  return n && unit ? Math.round(n * unit) : null;
}

/**
 * A direct file URL in the response body.
 *
 * The landing page states its own canonical URL (which ends in ".rar"), so a
 * naive "first URL that looks like a file" match returns the page itself and
 * would queue an HTML document as if it were the file. Candidates must differ
 * from the landing page and not repeat its /<id>/... shape.
 */
function isPlausibleDirect(candidate, link, id) {
  let c, l;
  try { c = new URL(candidate); l = new URL(link); } catch (e) { return false; }
  c.hash = '';
  if (c.toString() === l.toString()) return false;
  if (c.hostname === l.hostname && c.pathname.split('/').filter(Boolean)[0] === id) return false;
  return looksLikeFile(candidate);
}

function findDirectLink(html, link, id) {
  const patterns = [
    /["'](?:download_url|downloadUrl|direct_link|directLink|file_url|url)["']\s*:\s*["'](https?:\/\/[^"']+)["']/i,
    /<a[^>]+href=["'](https?:\/\/[^"']+)["'][^>]*(?:id|class)=["'][^"']*(?:download|btn-download|dlbtn)/i,
    /(?:id|class)=["'][^"']*(?:download|btn-download|dlbtn)[^"']*["'][^>]*href=["'](https?:\/\/[^"']+)["']/i,
    /window\.location(?:\.href)?\s*=\s*["'](https?:\/\/[^"']+)["']/i,
    /(https?:\/\/[a-z0-9.-]+\/(?:d|files)\/[^\s"'<>]+)/i,
  ];
  for (const re of patterns) {
    const m = html.match(re);
    if (m && isPlausibleDirect(m[1], link, id)) return m[1];
  }
  const any = html.match(/https?:\/\/[^\s"'<>]+/g) || [];
  for (const u of any) {
    if (isPlausibleDirect(u, link, id) &&
        !/\.(png|jpg|jpeg|gif|svg|css|js|ico|woff2?)(\?|$)/i.test(u)) {
      return u;
    }
  }
  return null;
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

module.exports = {
  name: 'datanodes',
  description: 'datanodes.to (XFileSharing; free downloads are Turnstile-gated)',

  match(url, parsed) {
    return /(^|\.)datanodes\.to$/i.test(parsed.hostname);
  },

  async resolve(link, ctx) {
    const { id, fname } = parseLink(link);
    if (!id) return result.error(link, 'could not find a file id in the URL');

    const headers = downloadHeaders(ctx, HOST, link);
    const common = {
      headers: { Cookie: headers.Cookie || '', Referer: link },
      userAgent: headers['User-Agent'],
      timeout: 30000,
      maxBytes: 4 * 1024 * 1024,
    };
    const form = (extra) => Object.assign(
      { op: 'download2', id, rand: '', referer: '', method_free: '1', method_premium: '', dl: '1' },
      extra
    );

    try {
      // Step 1: claim a download session and read back the server-issued token.
      const first = await ctx.http.request(ENDPOINT, Object.assign({}, common, {
        form: form({}), followRedirects: false,
      }));
      const body = first.body.toString('utf8');

      if (isChallenge(first, body)) return result.challenge(link, HOST);
      if (isDead(body)) return result.dead(link);

      const size = parseSize(body);
      const meta = { headers, downloadPage: link, name: fname || undefined, size };

      // A 302 here is the classic XFileSharing shortcut.
      if (first.status >= 300 && first.status < 400 && first.headers.location) {
        const direct = new URL(first.headers.location, ENDPOINT).toString();
        if (isPlausibleDirect(direct, link, id)) return result.direct(direct, meta);
      }
      const early = findDirectLink(body, link, id);
      if (early) return result.direct(early, meta);

      const cd = parseCountdown(body);
      if (!cd) {
        return Object.assign(result.passthrough(
          link, 'file page loaded but it carried no download session'
        ), meta);
      }

      // Free downloads sit behind a Cloudflare Turnstile widget. There is no
      // headless way past it, so say so plainly instead of queueing an HTML page.
      if (cd['has-captcha'] === 'true') {
        return Object.assign({
          status: 'challenge',
          kind: 'captcha',
          url: link,
          note: 'datanodes requires a Cloudflare Turnstile captcha per file',
        }, meta);
      }

      // Step 2: wait out the countdown, then repost with the issued token.
      const wait = Math.min(parseInt(cd.countdown, 10) || 0, 30);
      if (wait) {
        ctx.log.debug(HOST + ': waiting ' + wait + 's countdown for ' + (fname || id));
        await sleep((wait + 1) * 1000);
      }

      const second = await ctx.http.request(ENDPOINT, Object.assign({}, common, {
        form: form({
          rand: cd.rand || '',
          referer: cd.referer || '',
          method_free: cd['free-method'] || '1',
          method_premium: cd['premium-method'] || '',
        }),
        followRedirects: false,
      }));
      const body2 = second.body.toString('utf8');

      if (isChallenge(second, body2)) return result.challenge(link, HOST);

      const message = (body2.match(/message="([^"]*)"/) || [])[1];
      if (message && /captcha/i.test(message)) {
        return Object.assign({
          status: 'challenge', kind: 'captcha', url: link,
          note: 'datanodes rejected the request with "' + message + '"',
        }, meta);
      }

      if (second.status >= 300 && second.status < 400 && second.headers.location) {
        const direct = new URL(second.headers.location, ENDPOINT).toString();
        if (isPlausibleDirect(direct, link, id)) return result.direct(direct, meta);
      }
      const found = findDirectLink(body2, link, id);
      if (found) return result.direct(found, meta);

      return Object.assign(result.passthrough(
        link,
        'no direct link after the countdown' + (message ? ' (' + message + ')' : '')
      ), meta);
    } catch (e) {
      return result.error(link, 'datanodes request failed: ' + e.message);
    }
  },
};
