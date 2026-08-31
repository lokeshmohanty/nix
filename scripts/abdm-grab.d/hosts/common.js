'use strict';
/** Helpers shared by the host resolvers. */

const { URL } = require('url');

/* Cloudflare's interstitial: HTTP 403/503 with the managed-challenge markup.
 * Distinguishing this from a genuine error matters, because the fix is
 * different -- the user must pass the challenge in Chrome, not retry. */
const CHALLENGE_MARKERS = [
  /Just a moment/i,
  /cf-browser-verification/i,
  /challenge-platform/i,
  /_cf_chl_opt/i,
  /Checking your browser/i,
  /Enable JavaScript and cookies to continue/i,
];

function isChallenge(res, body) {
  if (res.status !== 403 && res.status !== 503 && res.status !== 429) return false;
  const text = body != null ? body : '';
  return CHALLENGE_MARKERS.some((re) => re.test(text));
}

/* Hosts say "gone" in several languages and phrasings. */
const DEAD_MARKERS = [
  /File Not Found/i,
  /Fichier non trouv/i,
  /file (was )?(deleted|removed)/i,
  /no longer available/i,
  /has been removed/i,
  /invalid file link/i,
  /file does not exist/i,
];

function isDead(body) {
  return DEAD_MARKERS.some((re) => re.test(body || ''));
}

/** Standard result shapes, so every resolver reports the same vocabulary. */
const result = {
  direct: (url, extra) => Object.assign({ status: 'direct', url }, extra),
  passthrough: (url, note, extra) =>
    Object.assign({ status: 'passthrough', url, note }, extra),
  dead: (url, note) => ({ status: 'dead', url, note: note || 'file no longer exists on the host' }),
  challenge: (url, host) => ({
    status: 'challenge',
    url,
    note: 'Cloudflare challenge -- no valid clearance cookie for ' + host,
  }),
  error: (url, note) => ({ status: 'error', url, note }),
};

/** Build the header set a download needs: browser cookies, matching UA, referer. */
function downloadHeaders(ctx, host, referer) {
  const headers = {};
  const creds = ctx.cookiesFor(host);
  if (creds && creds.cookie) headers.Cookie = creds.cookie;
  const ua = ctx.userAgent || (creds && creds.userAgent);
  if (ua) headers['User-Agent'] = ua;
  headers.Referer = referer || 'https://' + host + '/';
  return headers;
}

const hostOf = (url) => {
  try { return new URL(url).hostname; } catch (e) { return ''; }
};

/** True when a URL looks like it points at a file rather than a landing page. */
const FILE_EXT_RE =
  /\.(rar|zip|7z|iso|bin|exe|tar|gz|xz|mkv|mp4|avi|mov|mp3|flac|pdf|epub|apk|dmg|z\d{2}|r\d{2}|\d{3})(\?|$)/i;

function looksLikeFile(url) {
  try {
    return FILE_EXT_RE.test(new URL(url).pathname);
  } catch (e) {
    return false;
  }
}

module.exports = {
  isChallenge, isDead, result, downloadHeaders, hostOf, looksLikeFile, FILE_EXT_RE,
};
