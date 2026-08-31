'use strict';
/** URL scraping shared by the source plugins. */

const { URL } = require('url');

const URL_RE = /((?:https?:\/\/|magnet:\?)[^\s<>"'\]\)]+)/gi;
/* Trailing punctuation that belongs to the prose, not the URL. */
const TRAILING_PUNCT = /[.,;:!?)\}>]+$/;

/** Bare http(s)/magnet URLs appearing anywhere in a block of text. */
function extractUrls(text) {
  const out = [];
  const seen = new Set();
  let m;
  URL_RE.lastIndex = 0;
  while ((m = URL_RE.exec(text)) !== null) {
    const u = m[1].replace(TRAILING_PUNCT, '');
    if (!seen.has(u)) { seen.add(u); out.push(u); }
  }
  return out;
}

/** Anchor targets first (resolved against the page), then bare URLs in the text. */
function extractFromHtml(html, baseUrl) {
  const out = [];
  const seen = new Set();
  const hrefRe = /<a\s[^>]*?href\s*=\s*["']([^"']+)["']/gi;
  let m;
  while ((m = hrefRe.exec(html)) !== null) {
    const raw = m[1].trim();
    if (!raw || raw.startsWith('#') || /^(javascript|mailto|tel):/i.test(raw)) continue;
    let href;
    try { href = new URL(raw, baseUrl).toString(); } catch (e) { continue; }
    if (!seen.has(href)) { seen.add(href); out.push(href); }
  }
  for (const u of extractUrls(html)) {
    if (!seen.has(u)) { seen.add(u); out.push(u); }
  }
  return out;
}

module.exports = { extractUrls, extractFromHtml };
