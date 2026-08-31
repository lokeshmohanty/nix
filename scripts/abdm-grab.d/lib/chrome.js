'use strict';
/*
 * Chrome cookie + User-Agent extraction (Linux).
 *
 * Cloudflare-protected hosts (fuckingfast.co and friends) only serve a download
 * once a `cf_clearance` cookie earned in a real browser is presented — together
 * with the *same* User-Agent that earned it, since clearance is bound to the UA.
 * So both are read from Chrome and travel together.
 *
 * Chrome on Linux encrypts cookie values with AES-128-CBC:
 *   key       = PBKDF2(password, "saltysalt", iterations=1, 16 bytes, SHA-1)
 *   IV        = 16 bytes of 0x20
 *   plaintext = SHA-256(host_key) + value + PKCS#7 padding
 * The password is "peanuts" for v10 and the gnome-keyring secret for v11; both
 * candidate keys are tried per cookie.
 *
 * This tool is Chrome-only by design -- other browsers were removed.
 */

const crypto = require('crypto');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawn, spawnSync, execFileSync } = require('child_process');
const log = require('./log');

const CHROME_CONFIG = path.join(os.homedir(), '.config', 'google-chrome');

function findSqlite3() {
  const candidates = [
    path.join(os.homedir(), '.nix-profile/bin/sqlite3'),
    '/run/current-system/sw/bin/sqlite3',
    '/usr/bin/sqlite3',
    '/usr/local/bin/sqlite3',
  ];
  for (const c of candidates) if (fs.existsSync(c)) return c;
  const which = spawnSync('sh', ['-c', 'command -v sqlite3'], { encoding: 'utf8' });
  return (which.stdout || '').trim() || null;
}

let cachedKeys = null;
function safeStorageKeys() {
  if (cachedKeys) return cachedKeys;
  const keys = [];
  try {
    const r = spawnSync('secret-tool', ['lookup', 'application', 'chrome'], {
      encoding: 'utf8', timeout: 5000,
    });
    if (r.status === 0 && r.stdout.trim()) {
      keys.push(crypto.pbkdf2Sync(r.stdout.trim(), 'saltysalt', 1, 16, 'sha1'));
    }
  } catch (e) { /* no gnome-keyring; peanuts alone may still work */ }
  keys.push(crypto.pbkdf2Sync('peanuts', 'saltysalt', 1, 16, 'sha1'));
  cachedKeys = keys;
  return keys;
}

/* Control characters that should never appear in a cookie value -- their
 * presence means the ciphertext was decrypted with the wrong key. */
const MOJIBAKE_RE = /[\x00-\x08\x0e-\x1f]/;

function decryptValue(encHex, keys) {
  const enc = Buffer.from(encHex, 'hex');
  const version = enc.slice(0, 3).toString();
  if (version !== 'v10' && version !== 'v11') return null;
  const ct = enc.slice(3);
  if (ct.length === 0 || ct.length % 16 !== 0) return null;
  const iv = Buffer.alloc(16, 0x20);
  for (const key of keys) {
    try {
      const d = crypto.createDecipheriv('aes-128-cbc', key, iv);
      d.setAutoPadding(false);
      let pt = Buffer.concat([d.update(ct), d.final()]);
      const pad = pt[pt.length - 1];
      if (pad > 0 && pad <= 16) pt = pt.slice(0, pt.length - pad);
      if (pt.length <= 32) continue;           // 32-byte domain hash only, no value
      const value = pt.slice(32).toString('utf8');
      if (MOJIBAKE_RE.test(value)) continue;   // wrong key
      return value;
    } catch (e) { /* wrong key, try the next */ }
  }
  return null;
}

/** Chrome profile directories that actually contain a cookie DB. */
function profiles(only) {
  if (!fs.existsSync(CHROME_CONFIG)) return [];
  const out = [];
  for (const entry of fs.readdirSync(CHROME_CONFIG)) {
    if (only && entry !== only) continue;
    const p = path.join(CHROME_CONFIG, entry, 'Cookies');
    if (fs.existsSync(p)) out.push({ profile: entry, db: p });
  }
  // "Default" first -- it is the profile most people actually browse in.
  out.sort((a, b) => (a.profile === 'Default' ? -1 : b.profile === 'Default' ? 1 : 0));
  return out;
}

let cachedUa;
/** Build the UA string for the installed Chrome, so it matches cf_clearance. */
function userAgent() {
  if (cachedUa !== undefined) return cachedUa;
  for (const bin of ['google-chrome-stable', 'google-chrome', 'chrome']) {
    try {
      const v = execFileSync(bin, ['--version'], {
        encoding: 'utf8', timeout: 5000, stdio: ['ignore', 'pipe', 'ignore'],
      }).trim();
      const m = v.match(/(\d+\.\d+\.\d+\.\d+)/);
      if (m) {
        cachedUa = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 ' +
                   '(KHTML, like Gecko) Chrome/' + m[1] + ' Safari/537.36';
        return cachedUa;
      }
    } catch (e) { /* not this binary */ }
  }
  cachedUa = null;
  return null;
}

/** Domain patterns matching cookies for `domain`, including parent domains. */
function domainPatterns(domain) {
  const pats = new Set([domain, '.' + domain]);
  const parts = domain.split('.');
  for (let i = 1; i <= parts.length - 2; i++) {
    const parent = parts.slice(i).join('.');
    pats.add(parent);
    pats.add('.' + parent);
  }
  return [...pats];
}

const cookieCache = new Map();

/**
 * Read cookies for a domain out of Chrome.
 * @returns {{cookie: string, userAgent: string|null, count: number}|null}
 */
function cookiesFor(domain, opts) {
  opts = opts || {};
  if (cookieCache.has(domain)) return cookieCache.get(domain);

  let result = null;
  const sqlite3 = findSqlite3();
  const dirs = profiles(opts.profile);

  if (!sqlite3) {
    log.debug('sqlite3 not found -- cannot read Chrome cookies');
  } else if (!dirs.length) {
    log.debug('no Chrome profile with a cookie DB under ' + CHROME_CONFIG);
  } else {
    const keys = safeStorageKeys();
    const where = domainPatterns(domain)
      .map((p) => "host_key = '" + p.replace(/'/g, "''") + "'")
      .join(' OR ');
    const found = [];

    for (const { profile, db } of dirs) {
      // Chrome holds a lock on the live DB; work on a copy.
      const tmp = path.join(
        os.tmpdir(), 'abdm-cookies-' + process.pid + '-' + Math.random().toString(36).slice(2) + '.db'
      );
      try {
        fs.copyFileSync(db, tmp);
        const q = 'SELECT host_key, name, hex(encrypted_value), path FROM cookies WHERE ' + where + ';';
        const r = spawnSync(sqlite3, [tmp, q], { encoding: 'utf8', timeout: 10000 });
        if (r.status !== 0 || !r.stdout.trim()) continue;
        for (const line of r.stdout.trim().split('\n')) {
          const [hostKey, name, hex, cpath] = line.split('|');
          if (!name || !hex) continue;
          const value = decryptValue(hex, keys);
          if (value !== null) {
            found.push({ name, value, domain: hostKey, path: cpath || '/', profile });
          }
        }
      } catch (e) {
        log.debug('cookie read failed for ' + profile + ': ' + e.message);
      } finally {
        try { fs.unlinkSync(tmp); } catch (e) { /* already gone */ }
      }
    }

    if (found.length) {
      // Most specific host_key wins when the same name appears more than once.
      found.sort((a, b) => b.domain.length - a.domain.length);
      const seen = new Set();
      const parts = [];
      for (const c of found) {
        if (seen.has(c.name)) continue;
        seen.add(c.name);
        parts.push(c.name + '=' + c.value);
      }
      result = { cookie: parts.join('; '), userAgent: userAgent(), count: seen.size };
    }
  }

  cookieCache.set(domain, result);
  return result;
}

/** Open a URL in Chrome (used by --open-site to earn a Cloudflare clearance). */
function open(url) {
  for (const bin of ['google-chrome-stable', 'google-chrome', 'chrome', 'xdg-open']) {
    try {
      const child = spawn(bin, [url], { stdio: 'ignore', detached: true });
      child.unref();
      return bin;
    } catch (e) { /* try the next launcher */ }
  }
  return null;
}

/**
 * Drop cached cookie reads. Needed after sending the user to Chrome to earn a
 * fresh clearance: the whole point is that the cookie changed under us.
 */
function forget(domain) {
  if (domain) cookieCache.delete(domain);
  else cookieCache.clear();
}

module.exports = { cookiesFor, userAgent, open, profiles, forget, CHROME_CONFIG };
