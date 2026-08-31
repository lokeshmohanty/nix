'use strict';
/*
 * DNS with an automatic DNS-over-HTTPS fallback.
 *
 * Why this exists: some ISPs (observed here: Airtel, via an RPZ zone) hijack
 * lookups for file hosts such as multiup.io and answer with a sinkhole address
 * — `getent hosts multiup.io` returns `restricted.rpz.airtelspam.com`, and every
 * connection to it hangs until it times out. The block is intermittent, so the
 * tool cannot simply assume one path works.
 *
 * Strategy, cheapest first:
 *   1. dns.resolve4 (c-ares, reads /etc/resolv.conf directly). This already
 *      dodges an nsswitch/`hosts`-level hijack, which is the common case.
 *   2. If the answer looks like a sinkhole (reverse DNS mentions rpz/blocked/…),
 *      or a connection to it failed, resolve over DoH instead and connect to
 *      that address directly. TLS still uses the real hostname for SNI and
 *      certificate validation, so this is a DNS bypass, not a security bypass.
 *
 * Exposes a `lookup` implementation with the signature Node's http/https agents
 * expect, so it can be handed straight to https.request({ lookup }).
 */

const dns = require('dns');
const https = require('https');
const log = require('./log');

const DEFAULT_DOH = 'https://cloudflare-dns.com/dns-query';

/* Sinkhole/blockpage hostnames used by ISP RPZ deployments. */
const SINKHOLE_RE = /\b(rpz|blocked?|blockpage|restricted|blacklist|sinkhole|spam)\b/i;

const cache = new Map();      // hostname -> { addrs: string[], via: 'system'|'doh' }
const forceDoh = new Set();   // hostnames known to be hijacked this run

let config = { enabled: true, url: DEFAULT_DOH };

function configure(opts) {
  if (opts.doh === false) config.enabled = false;
  if (typeof opts.doh === 'string') config.url = opts.doh;
}

const resolve4 = (host) =>
  new Promise((res) => dns.resolve4(host, (e, a) => res(e ? [] : a || [])));

const reverse = (ip) =>
  new Promise((res) => dns.reverse(ip, (e, n) => res(e ? [] : n || [])));

/** True when the addresses look like an ISP block page rather than the real host. */
async function looksHijacked(addrs) {
  for (const ip of addrs.slice(0, 2)) {
    const names = await reverse(ip);
    if (names.some((n) => SINKHOLE_RE.test(n))) return true;
  }
  return false;
}

/** Resolve A records through DNS-over-HTTPS (JSON API). */
function resolveDoh(hostname) {
  return new Promise((resolve) => {
    const url = `${config.url}?name=${encodeURIComponent(hostname)}&type=A`;
    const req = https.get(
      url,
      { headers: { accept: 'application/dns-json' }, timeout: 10000 },
      (res) => {
        const chunks = [];
        res.on('data', (c) => chunks.push(c));
        res.on('end', () => {
          try {
            const body = JSON.parse(Buffer.concat(chunks).toString('utf8'));
            const addrs = (body.Answer || [])
              .filter((a) => a.type === 1 && a.data)
              .map((a) => a.data);
            resolve(addrs);
          } catch (e) {
            resolve([]);
          }
        });
      }
    );
    req.on('error', () => resolve([]));
    req.on('timeout', () => { req.destroy(); resolve([]); });
  });
}

/**
 * Resolve a hostname, preferring the system resolver and falling back to DoH
 * when the answer is missing or looks hijacked.
 * @returns {Promise<{addrs: string[], via: string}>}
 */
async function resolveHost(hostname) {
  if (cache.has(hostname)) return cache.get(hostname);

  let result = null;
  if (!forceDoh.has(hostname)) {
    const addrs = await resolve4(hostname);
    if (addrs.length && !(await looksHijacked(addrs))) {
      result = { addrs, via: 'system' };
    } else if (addrs.length) {
      log.warn(
        `${hostname} resolves to a block page (${addrs[0]}) — your ISP is hijacking this lookup; using DNS-over-HTTPS`
      );
    }
  }

  if (!result && config.enabled) {
    const addrs = await resolveDoh(hostname);
    if (addrs.length) {
      log.debug(`doh: ${hostname} -> ${addrs.join(', ')}`);
      result = { addrs, via: 'doh' };
    }
  }

  if (!result) result = { addrs: [], via: 'none' };
  cache.set(hostname, result);
  return result;
}

/** Mark a host as hijacked so subsequent lookups go straight to DoH. */
function markBlocked(hostname) {
  forceDoh.add(hostname);
  cache.delete(hostname);
}

/**
 * A `lookup` function for http/https request options. Falls back to the
 * platform resolver if both strategies come up empty, so behaviour never gets
 * worse than Node's default.
 */
function lookup(hostname, options, callback) {
  if (typeof options === 'function') { callback = options; options = {}; }
  resolveHost(hostname).then((r) => {
    if (!r.addrs.length) return dns.lookup(hostname, options, callback);
    if (options && options.all) {
      return callback(null, r.addrs.map((address) => ({ address, family: 4 })));
    }
    callback(null, r.addrs[0], 4);
  });
}

module.exports = { configure, resolveHost, markBlocked, lookup, DEFAULT_DOH };
