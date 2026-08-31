'use strict';
/*
 * HTTP client used by every source and host plugin.
 *
 * Beyond Node's built-ins it adds: transparent gzip/deflate/br decoding,
 * redirect following that preserves the cookie jar, form POSTs, the DoH-aware
 * lookup from lib/doh.js, and a retry that flips a host over to DoH when a
 * connection times out (the shape an ISP sinkhole takes).
 */

const http = require('http');
const https = require('https');
const zlib = require('zlib');
const { URL } = require('url');
const doh = require('./doh');
const log = require('./log');

/* A current desktop Chrome UA. Overridden by the real browser UA when cookies
 * are extracted, because Cloudflare ties clearance cookies to the UA string. */
const DEFAULT_UA =
  'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) ' +
  'Chrome/140.0.0.0 Safari/537.36';

function decompress(buf, encoding) {
  try {
    if (encoding === 'gzip') return zlib.gunzipSync(buf);
    if (encoding === 'deflate') {
      try { return zlib.inflateSync(buf); } catch (e) { return zlib.inflateRawSync(buf); }
    }
    if (encoding === 'br') return zlib.brotliDecompressSync(buf);
  } catch (e) {
    log.debug(`decompress(${encoding}) failed: ${e.message}`);
  }
  return buf;
}

const isTimeout = (err) =>
  err && (err.code === 'ETIMEDOUT' || err.code === 'ECONNRESET' ||
          /timed out/i.test(err.message || ''));

/** One request, no redirect handling. */
function once(target, opts) {
  return new Promise((resolve, reject) => {
    let parsed;
    try { parsed = new URL(target); } catch (e) {
      return reject(new Error(`invalid URL: ${target}`));
    }
    const lib = parsed.protocol === 'http:' ? http : https;
    const headers = Object.assign(
      {
        'User-Agent': opts.userAgent || DEFAULT_UA,
        Accept: opts.accept || '*/*',
        'Accept-Language': 'en-US,en;q=0.9',
        'Accept-Encoding': 'gzip, deflate, br',
      },
      opts.headers || {}
    );
    let body = opts.body;
    if (opts.form) {
      body = new URLSearchParams(opts.form).toString();
      headers['Content-Type'] = 'application/x-www-form-urlencoded';
    }
    if (body != null) headers['Content-Length'] = Buffer.byteLength(body);

    const req = lib.request(
      parsed,
      {
        method: opts.method || (body != null ? 'POST' : 'GET'),
        headers,
        timeout: opts.timeout || 30000,
        lookup: doh.lookup,
      },
      (res) => {
        // HEAD requests and explicit no-body reads should not buffer the file.
        if (opts.method === 'HEAD' || opts.noBody) {
          res.resume();
          return resolve({
            status: res.statusCode, headers: res.headers,
            body: Buffer.alloc(0), url: parsed.toString(),
          });
        }
        const chunks = [];
        let size = 0;
        res.on('data', (c) => {
          chunks.push(c);
          size += c.length;
          // Guard against accidentally slurping a multi-GB file into memory.
          if (opts.maxBytes && size > opts.maxBytes) {
            res.destroy();
            resolve({
              status: res.statusCode, headers: res.headers,
              body: Buffer.concat(chunks), url: parsed.toString(), truncated: true,
            });
          }
        });
        res.on('end', () => {
          const raw = Buffer.concat(chunks);
          resolve({
            status: res.statusCode,
            headers: res.headers,
            body: decompress(raw, (res.headers['content-encoding'] || '').toLowerCase()),
            url: parsed.toString(),
          });
        });
        res.on('error', reject);
      }
    );
    req.on('error', reject);
    req.on('timeout', () => req.destroy(Object.assign(
      new Error(`request timed out after ${opts.timeout || 30000}ms`), { code: 'ETIMEDOUT' }
    )));
    if (body != null) req.write(body);
    req.end();
  });
}

/**
 * Request with redirect following and a DoH retry.
 * @returns {Promise<{status, headers, body: Buffer, url, redirects: string[]}>}
 */
async function request(target, opts) {
  opts = opts || {};
  const maxRedirects = opts.maxRedirects != null ? opts.maxRedirects : 10;
  const redirects = [];
  let current = target;
  let attemptedDoh = false;

  for (let hop = 0; ; hop++) {
    let res;
    try {
      res = await once(current, opts);
    } catch (err) {
      // A timeout is what an ISP sinkhole looks like from here: DNS answered,
      // but the address never completes a handshake. Retry once over DoH.
      if (isTimeout(err) && !attemptedDoh) {
        attemptedDoh = true;
        const host = new URL(current).hostname;
        log.debug(`${host}: ${err.message} — retrying via DNS-over-HTTPS`);
        doh.markBlocked(host);
        continue;
      }
      throw err;
    }

    if (res.status >= 300 && res.status < 400 && res.headers.location &&
        opts.followRedirects !== false) {
      if (hop >= maxRedirects) throw new Error(`too many redirects (>${maxRedirects})`);
      const next = new URL(res.headers.location, current).toString();
      redirects.push(next);
      // A 303, or a 301/302 after a POST, continues as GET per browser behaviour.
      if (opts.form || opts.body) {
        opts = Object.assign({}, opts, { form: null, body: null, method: 'GET' });
      }
      current = next;
      continue;
    }

    res.redirects = redirects;
    return res;
  }
}

/** Convenience: fetch and decode as UTF-8 text. */
async function text(target, opts) {
  const res = await request(target, opts);
  return Object.assign(res, { text: res.body.toString('utf8') });
}

/**
 * Follow a URL without downloading it, to learn the final URL, size and
 * filename. Uses a ranged GET because many file hosts reject HEAD.
 */
async function probe(target, opts) {
  opts = Object.assign({}, opts, {
    noBody: true,
    headers: Object.assign({ Range: 'bytes=0-0' }, (opts && opts.headers) || {}),
  });
  const res = await request(target, opts);
  const cd = res.headers['content-disposition'] || '';
  const m = cd.match(/filename\*?=(?:UTF-8''|")?([^";]+)/i);
  let size = null;
  const cr = res.headers['content-range'];
  if (cr) {
    const rm = cr.match(/\/(\d+)\s*$/);
    if (rm) size = parseInt(rm[1], 10);
  } else if (res.headers['content-length']) {
    size = parseInt(res.headers['content-length'], 10);
  }
  return {
    status: res.status,
    url: res.url,
    size,
    filename: m ? decodeURIComponent(m[1].replace(/"$/, '')) : null,
    contentType: (res.headers['content-type'] || '').split(';')[0].trim(),
  };
}

module.exports = { request, text, probe, DEFAULT_UA };
