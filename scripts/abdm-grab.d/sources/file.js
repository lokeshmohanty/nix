'use strict';
/*
 * Source: a local file -- a saved web page, or a plain text file with one link
 * per line. Useful for feeding the tool a list you assembled by hand, and for
 * re-running against a page you already downloaded.
 */

const fs = require('fs');
const { URL } = require('url');
const { extractUrls, extractFromHtml } = require('../lib/extract');

module.exports = {
  name: 'file',
  description: 'a local HTML page or text file of links (path or file:// URL)',

  match(url, parsed) {
    return parsed.protocol === 'file:';
  },

  async extract(url) {
    const filePath = decodeURIComponent(new URL(url).pathname);
    let text;
    try {
      text = fs.readFileSync(filePath, 'utf8');
    } catch (e) {
      throw new Error('could not read ' + filePath + ': ' + e.message);
    }
    const isHtml = /<a\s|<html|<body/i.test(text);
    return {
      title: (text.match(/<title[^>]*>([^<]*)<\/title>/i) || [, null])[1],
      links: isHtml ? extractFromHtml(text, url) : extractUrls(text),
      pageUrl: null,
    };
  },
};
