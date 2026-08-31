'use strict';
/*
 * Host registry -- "given a file-host landing page, how do I get a direct
 * download URL out of it".
 *
 * First match wins, and passthrough is last because it matches everything. To
 * support a new file host, add a module here exporting
 *   { name, description, match(url, parsed), resolve(link, ctx) }
 * where resolve returns one of the shapes in hosts/common.js `result`.
 *
 * ctx provides: http, cookiesFor(host), userAgent, log, opts, pageUrl and
 * resolveNested(url) for aggregators that point at another host.
 */

const { URL } = require('url');

const HOSTS = [
  require('./fuckingfast'),
  require('./datanodes'),
  require('./passthrough'),   // must stay last: matches unconditionally
];

function pick(url) {
  let parsed;
  try { parsed = new URL(url); } catch (e) { return HOSTS[HOSTS.length - 1]; }
  return HOSTS.find((h) => h.match(url, parsed));
}

module.exports = { HOSTS, pick };
