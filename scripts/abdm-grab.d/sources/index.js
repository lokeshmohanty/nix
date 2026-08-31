'use strict';
/*
 * Source registry -- "what kind of link is this, and how do I get the file
 * links out of it".
 *
 * Order matters: the first plugin whose match() returns true wins, and html is
 * deliberately last because it matches everything. To teach the tool a new kind
 * of source, drop a module in this directory exporting
 * { name, description, match(url, parsed), extract(url, ctx) } and list it here.
 */

const { URL } = require('url');

const SOURCES = [
  require('./file'),
  require('./privatebin'),
  require('./html'),          // must stay last: matches unconditionally
];

/** @returns the source plugin that should handle `url` */
function pick(url, forced) {
  if (forced) {
    const found = SOURCES.find((s) => s.name === forced);
    if (!found) {
      throw new Error(
        'unknown source "' + forced + '" (have: ' + SOURCES.map((s) => s.name).join(', ') + ')'
      );
    }
    return found;
  }
  const parsed = new URL(url);
  return SOURCES.find((s) => s.match(url, parsed));
}

module.exports = { SOURCES, pick };
