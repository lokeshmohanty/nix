'use strict';
/*
 * Browser-impersonating HTTP transport (curl-impersonate).
 *
 * Cloudflare-protected hosts cannot be fetched from Node at all -- not because
 * of cookies or headers, but because Cloudflare fingerprints the TLS
 * ClientHello and HTTP/2 settings. Node's TLS stack is trivially
 * distinguishable from Chrome's, so a *valid* cf_clearance cookie still comes
 * back as "Just a moment...". Verified directly: identical cookies and full
 * Chrome client-hint headers returned 403 from Node and 200 from
 * curl-impersonate.
 *
 * curl-impersonate is a curl build linked against BoringSSL that reproduces a
 * real Chrome handshake, so the clearance cookie is accepted. It is used only
 * for hosts that ask for it; everything else stays on the cheap Node path.
 */

const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const log = require('./log');

/* Newest first -- a recent profile is likelier to match current Chrome. */
const BINARIES = [
  'curl_chrome146', 'curl_chrome145', 'curl_chrome142', 'curl_chrome136',
  'curl_chrome133a', 'curl_chrome131', 'curl_chrome124', 'curl_chrome123',
  'curl_chrome120', 'curl_chrome119', 'curl_chrome116', 'curl_chrome110',
];

let cached;

/** Locate a curl-impersonate binary, or null. */
function find() {
  if (cached !== undefined) return cached;

  if (process.env.ABDM_GRAB_CURL && fs.existsSync(process.env.ABDM_GRAB_CURL)) {
    cached = process.env.ABDM_GRAB_CURL;
    return cached;
  }
  for (const name of BINARIES) {
    const r = spawnSync('sh', ['-c', 'command -v ' + name], { encoding: 'utf8' });
    const found = (r.stdout || '').trim();
    if (found) { cached = found; return cached; }
  }
  cached = null;
  return cached;
}

let warned = false;
function warnMissing(host) {
  if (warned) return;
  warned = true;
  log.warn(
    `${host} is behind Cloudflare, which fingerprints the TLS handshake -- Node\n` +
    '        cannot fetch it even with a valid clearance cookie. Install\n' +
    '        curl-impersonate to resolve these links:\n' +
    '          nix profile install nixpkgs#curl-impersonate\n' +
    '        (or add it to your home-manager packages and switch).'
  );
}

const available = () => find() !== null;

/**
 * Perform a request through curl-impersonate.
 * Mirrors the shape returned by lib/http.js `request`.
 *
 * @returns {{status, headers, body: Buffer, url}}
 */
function request(url, opts) {
  opts = opts || {};
  const bin = find();
  if (!bin) throw new Error('curl-impersonate is not installed');

  const headerFile = path.join(
    require('os').tmpdir(),
    'abdm-grab-hdr-' + process.pid + '-' + Math.random().toString(36).slice(2)
  );
  const args = [
    '--silent', '--show-error',
    '--max-time', String(Math.ceil((opts.timeout || 30000) / 1000)),
    '--dump-header', headerFile,
    '--output', '-',
    '--write-out', '\\n%{http_code} %{url_effective}',
  ];
  if (opts.followRedirects !== false) args.push('--location');

  for (const [k, v] of Object.entries(opts.headers || {})) {
    if (v) args.push('--header', k + ': ' + v);
  }
  if (opts.form) {
    args.push('--data', new URLSearchParams(opts.form).toString());
  } else if (opts.body != null) {
    args.push('--data-binary', opts.body);
  }
  if (opts.method && opts.method !== 'GET') args.push('--request', opts.method);
  args.push(url);

  const r = spawnSync(bin, args, {
    encoding: 'buffer',
    timeout: (opts.timeout || 30000) + 5000,
    maxBuffer: opts.maxBytes || 16 * 1024 * 1024,
  });

  let headers = {};
  try {
    // --location writes one header block per hop; the last one is the response.
    const raw = fs.readFileSync(headerFile, 'utf8');
    const blocks = raw.split(/\r?\n\r?\n/).filter((b) => b.trim());
    for (const line of (blocks[blocks.length - 1] || '').split(/\r?\n/)) {
      const i = line.indexOf(':');
      if (i > 0) headers[line.slice(0, i).trim().toLowerCase()] = line.slice(i + 1).trim();
    }
  } catch (e) {
    log.debug('could not read impersonate headers: ' + e.message);
  } finally {
    try { fs.unlinkSync(headerFile); } catch (e) { /* already gone */ }
  }

  if (r.error) throw new Error('curl-impersonate failed: ' + r.error.message);

  const out = r.stdout || Buffer.alloc(0);
  // The trailing "\n<code> <url>" from --write-out is metadata, not body.
  const text = out.toString('binary');
  const nl = text.lastIndexOf('\n');
  const trailer = nl === -1 ? '' : text.slice(nl + 1);
  const m = trailer.match(/^(\d{3})\s+(\S*)$/);
  const body = m ? out.subarray(0, nl) : out;

  return {
    status: m ? parseInt(m[1], 10) : 0,
    headers,
    body,
    url: m && m[2] ? m[2] : url,
    redirects: [],
  };
}

/** Same as request(), but decoded as UTF-8 text. */
function text(url, opts) {
  const res = request(url, opts);
  return Object.assign(res, { text: res.body.toString('utf8') });
}

module.exports = { find, available, request, text, warnMissing };
