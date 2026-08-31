'use strict';
/*
 * Deriving human names from links.
 *
 * The queue name defaults to the longest filename prefix the downloads share,
 * cleaned up: for a set like
 *   MGSV_TPP_--_fitgirl-repacks.site_--_.part1.rar ... .part6.rar
 * the common prefix is "MGSV_TPP_--_fitgirl-repacks.site_--_.part", which after
 * stripping the site marker, the part/volume suffix and separators becomes
 * "MGSV TPP".
 */

const { URL } = require('url');

/* Site watermarks repackers embed in every filename -- never part of the name. */
const WATERMARKS = [
  /[-_. ]*fitgirl[-_. ]?repacks?(\.site)?[-_. ]*/gi,
  /[-_. ]*dodi[-_. ]?repacks?[-_. ]*/gi,
  /[-_. ]*empress[-_. ]*/gi,
  /[-_. ]*\[?rutracker\]?[-_. ]*/gi,
];

/* One trailing archive/media extension or volume marker: .rar, .7z, .001,
 * .r00, .part03, .mkv ... Applied repeatedly to peel ".7z.001" style tails. */
const TAIL_TOKEN =
  /[\s._-](rar|zip|7z|iso|bin|tar|gz|exe|mkv|mp4|avi|mp3|flac|pdf|z\d{2}|r\d{2}|\d{3}|(part|vol|volume|disc|cd|pt)\s*\d*)$/i;

function hostOf(url) {
  try { return new URL(url).hostname; } catch (e) { return ''; }
}

/**
 * Best-effort filename for a link. Many hosts put the real name in the
 * fragment (fuckingfast.co/<id>#name.rar) or the last path segment.
 */
function deriveFilename(url) {
  let parsed;
  try { parsed = new URL(url); } catch (e) { return 'download'; }

  if (parsed.hash && parsed.hash.length > 1) {
    const frag = decodeURIComponent(parsed.hash.slice(1));
    if (frag && !frag.includes('/')) return frag;
  }
  const segments = parsed.pathname.split('/').filter(Boolean);
  for (let i = segments.length - 1; i >= 0; i--) {
    const seg = decodeURIComponent(segments[i]);
    // Prefer a segment that looks like a filename over an opaque id.
    if (seg.includes('.')) return seg;
  }
  if (segments.length) return decodeURIComponent(segments[segments.length - 1]);
  return parsed.hostname || 'download';
}

/** Longest common prefix of a list of strings. */
function commonPrefix(strings) {
  if (!strings.length) return '';
  let prefix = strings[0];
  for (const s of strings.slice(1)) {
    let i = 0;
    while (i < prefix.length && i < s.length && prefix[i] === s[i]) i++;
    prefix = prefix.slice(0, i);
    if (!prefix) break;
  }
  return prefix;
}

/** Turn a raw filename fragment into a title: separators to spaces, tidy case. */
function titleize(raw) {
  let s = raw;
  for (const re of WATERMARKS) s = s.replace(re, ' ');
  s = s.replace(/[\s._-]+$/, '');

  // Peel trailing extension/volume tokens one at a time, so ".7z.001" and
  // ".part01.rar" both reduce to the bare title.
  for (let i = 0; i < 6; i++) {
    const next = s.replace(TAIL_TOKEN, '');
    if (next === s) break;
    s = next;
  }

  // Separators become spaces, but a dot between two digits is a version
  // number ("v2.1"), not a separator.
  s = s.replace(/_+/g, ' ').replace(/\.(?!\d)/g, ' ').replace(/(?<=\D)\.(?=\d)/g, ' ');
  s = s.replace(/\s*-\s*-\s*/g, ' ');
  // A longest-common-prefix cut can leave a bare volume keyword behind
  // (".part1"/".part2" share ".part"); drop it now that separators are spaces.
  s = s.replace(/[\s._-]*\b(part|vol|volume|disc|cd|pt)\s*\d*$/i, '');
  s = s.replace(/[\s-]+$/, '').replace(/^[\s-]+/, '');
  s = s.replace(/\s{2,}/g, ' ').trim();
  return s;
}

/**
 * Derive a queue name from the links being added.
 * Falls back to the source page title, then the host, then a generic label.
 * @param {{name: string, url: string}[]} links
 * @param {{title?: string}} [ctx]
 */
function deriveQueueName(links, ctx) {
  ctx = ctx || {};
  const names = links.map((l) => l.name).filter(Boolean);

  if (names.length > 1) {
    // The common prefix necessarily stops mid-token -- the next character is
    // what differs between filenames -- so ".part1"/".part6" yield ".part" and
    // ".7z.001"/".7z.002" yield ".7z.00". Drop that trailing partial token.
    const prefix = commonPrefix(names).replace(/[^\s._-]*$/, '');
    const candidate = titleize(prefix);
    // A one- or two-character prefix is coincidence, not a name.
    if (candidate.length >= 3) return candidate;
  }
  if (names.length === 1) {
    const candidate = titleize(names[0]);
    if (candidate.length >= 3) return candidate;
  }
  if (ctx.title) {
    const candidate = titleize(ctx.title);
    if (candidate.length >= 3) return candidate;
  }
  const host = links.length ? hostOf(links[0].url) : '';
  return host || 'abdm-grab';
}

/** Make a string safe to use as a directory name. */
function sanitizePath(name) {
  return name.replace(/[\/\0]/g, '-').replace(/\s{2,}/g, ' ').trim() || 'downloads';
}

function formatSize(bytes) {
  if (bytes == null || !isFinite(bytes)) return null;
  const units = ['B', 'KiB', 'MiB', 'GiB', 'TiB'];
  let v = bytes, i = 0;
  while (v >= 1024 && i < units.length - 1) { v /= 1024; i++; }
  return (i === 0 ? v : v.toFixed(v < 10 ? 2 : 1)) + ' ' + units[i];
}

module.exports = {
  deriveFilename, deriveQueueName, commonPrefix, titleize,
  sanitizePath, formatSize, hostOf,
};
