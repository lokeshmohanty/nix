'use strict';
/*
 * Host fallback: anything with no dedicated resolver.
 *
 * If the URL already looks like a file it is handed straight to ABDM. Otherwise
 * the tool probes it (ranged GET, following redirects) to see whether it lands
 * on a file -- which covers the many hosts that are just a redirect -- and
 * passes the landing URL through if it does not.
 */

const { result, downloadHeaders, hostOf, looksLikeFile } = require('./common');

module.exports = {
  name: 'passthrough',
  description: 'any other host (direct URLs, or a redirect probe)',

  match() { return true; },   // must stay last in the registry

  async resolve(link, ctx) {
    const host = hostOf(link);
    const headers = downloadHeaders(ctx, host, link);

    if (/^magnet:/i.test(link)) {
      return result.passthrough(link, 'magnet link -- passed through untouched');
    }
    if (ctx.opts.noProbe) {
      // Without a probe the extension is the only signal available.
      return looksLikeFile(link)
        ? result.direct(link, { headers, downloadPage: ctx.pageUrl })
        : result.passthrough(link, 'not probed (--no-probe)', { headers });
    }

    try {
      const probe = await ctx.http.probe(link, {
        headers: { Cookie: headers.Cookie || '', Referer: headers.Referer },
        userAgent: headers['User-Agent'],
        timeout: 20000,
      });
      const isFile =
        looksLikeFile(probe.url) ||
        !!probe.filename ||
        (probe.contentType && !/^text\/html|xhtml/.test(probe.contentType));

      if (probe.status >= 200 && probe.status < 400 && isFile) {
        return result.direct(probe.url, {
          headers,
          size: probe.size,
          name: probe.filename || undefined,
          downloadPage: link,
        });
      }
      // A URL ending in ".rar" is not evidence of a file: aggregator landing
      // pages carry the filename in their path and still 404. Trust the probe.
      if (probe.status === 404 || probe.status === 410) {
        return result.dead(link, 'host returned HTTP ' + probe.status);
      }
      return result.passthrough(link, 'not a direct file (HTTP ' + probe.status + ')', { headers });
    } catch (e) {
      return result.passthrough(link, 'probe failed: ' + e.message, { headers });
    }
  },
};
