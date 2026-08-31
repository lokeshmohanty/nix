'use strict';
/*
 * abdm-grab -- pull download links out of a page and queue them in AB Download
 * Manager.
 *
 * Pipeline:
 *   1. SOURCE   sources/ decides what kind of page each input URL is and
 *               extracts the file links from it (PrivateBin paste, web page).
 *   2. FILTER   --host / --filter / --range / --limit, then dedupe.
 *   3. RESOLVE  hosts/ turns each file-host landing page into a direct download
 *               URL plus the headers needed to fetch it (Chrome cookies, the
 *               matching User-Agent, a referer).
 *   4. PLAN     confirm the queue name (defaulted from the filenames) and ask
 *               for the download folder once.
 *   5. APPLY    create the queue if needed, then add every link to it.
 *
 * Adding a source or a host means dropping a module into sources/ or hosts/ and
 * listing it in that directory's index.js -- see the comments there.
 */

const os = require('os');
const fs = require('fs');
const path = require('path');
const { URL } = require('url');

const log = require('./lib/log');
const http = require('./lib/http');
const doh = require('./lib/doh');
const chrome = require('./lib/chrome');
const abdm = require('./lib/abdm');
const prompt = require('./lib/prompt');
const naming = require('./lib/naming');
const { pool } = require('./lib/pool');
const sources = require('./sources');
const hosts = require('./hosts');

// -- help -------------------------------------------------------------------

function help() {
  const { paint } = log;
  const h = (s) => paint.bold(s);
  return `${h('abdm-grab')} -- extract download links and queue them in AB Download Manager

${h('USAGE')}
  abdm-grab <url>... [options]

  With no options it runs the whole flow: pull the links, resolve each one to a
  direct download, confirm a queue name, ask for a download folder once, then
  add everything to that queue.

${h('SOURCES')} (how links are pulled out of a page)
${sources.SOURCES.map((s) => `  ${s.name.padEnd(12)} ${s.description}`).join('\n')}

${h('HOSTS')} (how a landing page becomes a direct download)
${hosts.HOSTS.map((s) => `  ${s.name.padEnd(12)} ${s.description}`).join('\n')}

${h('OPTIONS')}
  ${h('Selecting links')}
  --filter <regex>     Keep only links whose URL or filename matches.
  --host <substr>      Keep only links from hosts containing <substr>.
  --range <a>-<b>      Keep only links a..b (1-indexed, inclusive).
  --limit <n>          Keep only the first n links.

  ${h('Queue and folder')}
  --queue-name <name>  Queue name (skips the prompt).
  --queue <id>         Use an existing queue id instead of creating one.
  --folder <path>      Download folder (skips the prompt).
  --start              Start the downloads immediately.
  --start-queue        Start the queue after adding.
  -y, --yes            Accept every default; never prompt.

  ${h('Resolution')}
  --no-resolve         Skip host resolution; hand landing URLs to ABDM as-is.
  --no-probe           Do not probe unknown hosts with a ranged GET.
  --no-cookies         Do not read cookies from Chrome.
  --chrome-profile <p> Chrome profile to read cookies from (default: all, "Default" first).
  --user-agent <ua>    Override the User-Agent.
  --header <k: v>      Extra header for the downloads (repeatable).
  --open-site          Open the download hosts in Chrome to pass Cloudflare, then exit.
  --source <name>      Force a source plugin instead of auto-detecting.
  --concurrency <n>    Parallel resolutions (default 5).
  --doh <url>          DNS-over-HTTPS endpoint (default: Cloudflare).
  --no-doh             Disable the DNS-over-HTTPS fallback.

  ${h('Output')}
  --list               Print the extracted links and exit.
  --dry-run            Resolve and show the plan, but add nothing.
  -v, --verbose        Show per-request detail.
  -h, --help           Show this help.

${h('EXAMPLES')}
  abdm-grab 'https://paste.fitgirl-repacks.site/?abc#key'
  abdm-grab <url> --filter 'part0[1-3]' --start
  abdm-grab <url> --queue-name 'MGSV TPP' --folder ~/Games/MGSV -y
  abdm-grab <url> --open-site        # pass Cloudflare in Chrome, then re-run

${h('REQUIREMENTS')}
  AB Download Manager running with the HTTP API enabled
  (Settings > Integration > Enable API). Cookies come from Google Chrome only.
`;
}

// -- argument parsing -------------------------------------------------------

function parseArgs(argv) {
  const opts = {
    urls: [],
    filter: null, host: null, range: null, limit: null,
    queueName: null, queueId: null, folder: null,
    start: false, startQueue: false, yes: false,
    resolve: true, noProbe: false, cookies: true, chromeProfile: null,
    userAgent: null, headers: [], openSite: false, source: null,
    concurrency: 5, doh: undefined,
    list: false, dryRun: false, verbose: false,
  };

  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    const next = () => {
      if (i + 1 >= argv.length) throw new Error('missing value for ' + a);
      return argv[++i];
    };
    switch (a) {
      case '-h': case '--help': process.stdout.write(help()); process.exit(0); break;
      case '--filter': opts.filter = next(); break;
      case '--host': opts.host = next(); break;
      case '--range': {
        const r = next().split('-');
        opts.range = { start: parseInt(r[0], 10), end: parseInt(r[1] || r[0], 10) };
        break;
      }
      case '--limit': opts.limit = parseInt(next(), 10); break;
      case '--queue-name': opts.queueName = next(); break;
      case '--queue': opts.queueId = parseInt(next(), 10); break;
      case '--folder': opts.folder = next(); break;
      case '--start': opts.start = true; break;
      case '--start-queue': opts.startQueue = true; break;
      case '-y': case '--yes': opts.yes = true; break;
      case '--no-resolve': opts.resolve = false; break;
      case '--no-probe': opts.noProbe = true; break;
      case '--no-cookies': opts.cookies = false; break;
      case '--chrome-profile': opts.chromeProfile = next(); break;
      case '--user-agent': opts.userAgent = next(); break;
      case '--header': opts.headers.push(next()); break;
      case '--open-site': opts.openSite = true; break;
      case '--source': opts.source = next(); break;
      case '--concurrency': opts.concurrency = parseInt(next(), 10); break;
      case '--doh': opts.doh = next(); break;
      case '--no-doh': opts.doh = false; break;
      case '--list': opts.list = true; break;
      case '--dry-run': opts.dryRun = true; break;
      case '-v': case '--verbose': opts.verbose = true; break;
      default:
        if (a.startsWith('-') && a !== '-') throw new Error('unknown option: ' + a);
        opts.urls.push(a);
    }
  }
  return opts;
}

/** Expand `-` into URLs read from stdin, so the tool composes with pipes. */
function readStdinUrls() {
  let data = '';
  try { data = fs.readFileSync(0, 'utf8'); } catch (e) { return []; }
  return data.split(/\s+/).filter((s) => /^https?:\/\//i.test(s));
}

// -- stage 1: collect -------------------------------------------------------

async function collectLinks(opts) {
  const collected = [];
  for (const sourceUrl of opts.urls) {
    let plugin;
    try {
      plugin = sources.pick(sourceUrl, opts.source);
    } catch (e) {
      log.err(e.message);
      continue;
    }

    log.step('source', `${log.paint.bold(plugin.name)}  ${sourceUrl}`);
    let out;
    try {
      out = await plugin.extract(sourceUrl, { http, opts, log });
    } catch (e) {
      log.err(`${plugin.name}: ${e.message}`);
      continue;
    }

    const links = out.links || [];
    log.ok(`${links.length} link(s) extracted`);
    for (const url of links) {
      collected.push({
        url,
        name: naming.deriveFilename(url),
        pageUrl: out.pageUrl || sourceUrl,
        title: out.title || null,
      });
    }
  }
  return collected;
}

function applyFilters(links, opts) {
  let out = links;
  if (opts.host) {
    const needle = opts.host.toLowerCase();
    out = out.filter((l) => naming.hostOf(l.url).toLowerCase().includes(needle));
  }
  if (opts.filter) {
    let re;
    try { re = new RegExp(opts.filter, 'i'); }
    catch (e) { throw new Error('invalid --filter regex: ' + e.message); }
    out = out.filter((l) => re.test(l.url) || re.test(l.name));
  }
  if (opts.range) out = out.slice(opts.range.start - 1, opts.range.end);
  if (opts.limit != null) out = out.slice(0, opts.limit);

  const seen = new Set();
  return out.filter((l) => (seen.has(l.url) ? false : (seen.add(l.url), true)));
}

// -- stage 3: resolve -------------------------------------------------------

function makeResolveContext(opts, link) {
  const cookiesFor = (host) =>
    opts.cookies ? chrome.cookiesFor(host, { profile: opts.chromeProfile }) : null;

  const ctx = {
    http, log, opts, cookiesFor,
    userAgent: opts.userAgent || chrome.userAgent(),
    pageUrl: link.pageUrl,
  };
  return ctx;
}

async function resolveAll(links, opts) {
  if (!opts.resolve) {
    return links.map((l) => Object.assign({}, l, {
      status: 'passthrough', resolvedUrl: l.url, note: 'resolution disabled (--no-resolve)',
      headers: {},
    }));
  }

  const byHost = new Map();
  for (const l of links) {
    const h = naming.hostOf(l.url);
    byHost.set(h, (byHost.get(h) || 0) + 1);
  }
  log.step('resolve', [...byHost.entries()]
    .map(([h, n]) => `${log.paint.bold(h || 'unknown')} (${n})`).join(', '));

  let done = 0;
  const results = await pool(links, opts.concurrency, async (link) => {
    const plugin = hosts.pick(link.url);
    let r;
    try {
      r = await plugin.resolve(link.url, makeResolveContext(opts, link));
    } catch (e) {
      r = { status: 'error', url: link.url, note: 'resolver threw: ' + e.message };
    }
    // Safety net: a resolver claiming "direct" while handing back the URL it
    // was given has not resolved anything -- that would queue an HTML landing
    // page as if it were the file. Downgrade rather than trust it.
    if (r.status === 'direct' && r.url === link.url && plugin.name !== 'passthrough') {
      r = {
        status: 'passthrough', url: link.url, headers: r.headers,
        note: 'resolver returned the landing page unchanged',
      };
    }

    done++;
    if (!log.isVerbose() && process.stderr.isTTY) {
      process.stderr.write(`\r  resolving ${done}/${links.length}...`);
    }
    return Object.assign({}, link, {
      resolver: plugin.name,
      status: r.status,
      kind: r.kind || null,
      resolvedUrl: r.url || link.url,
      headers: r.headers || {},
      note: r.note || null,
      size: r.size != null ? r.size : null,
      ephemeral: !!r.ephemeral,
      downloadPage: r.downloadPage || link.pageUrl,
      name: r.name || link.name,
    });
  });
  if (!log.isVerbose() && process.stderr.isTTY) process.stderr.write('\r\x1b[K');
  return results;
}

const STATUS_LABEL = {
  direct: { text: 'ready', paint: (s) => log.paint.green(s) },
  passthrough: { text: 'unresolved', paint: (s) => log.paint.yellow(s) },
  challenge: { text: 'blocked', paint: (s) => log.paint.yellow(s) },
  dead: { text: 'gone', paint: (s) => log.paint.red(s) },
  error: { text: 'error', paint: (s) => log.paint.red(s) },
};

function reportResolution(results) {
  const groups = new Map();
  for (const r of results) {
    if (!groups.has(r.status)) groups.set(r.status, []);
    groups.get(r.status).push(r);
  }
  for (const [status, items] of groups) {
    const label = STATUS_LABEL[status] || { text: status, paint: (s) => s };
    log.info(`  ${label.paint(label.text.padEnd(11))} ${items.length}` +
             (items[0].note ? log.paint.dim('  ' + items[0].note) : ''));
  }
}

/** Open at most this many tabs at once, so a 60-part repack cannot bury Chrome. */
const MAX_TABS = 8;

function openInChrome(urls, label) {
  const batch = urls.slice(0, MAX_TABS);
  for (const u of batch) chrome.open(u);
  log.info(`  opened ${batch.length} ${label} in Chrome`);
  if (urls.length > batch.length) {
    log.info(log.paint.dim(`  (${urls.length - batch.length} more not opened -- rerun to continue)`));
  }
}

/**
 * Blocked links need a browser, but for two different reasons with two
 * different remedies. Both open the *file* pages rather than the host root:
 * Cloudflare only challenges on the file page, so visiting the front page mints
 * no clearance at all.
 *
 *   clearance -- the host is behind a Cloudflare interstitial and Chrome holds
 *                no fresh cf_clearance. Loading one file page mints a cookie
 *                good for the rest, so re-resolving afterwards usually works.
 *   captcha   -- the host demands a Turnstile solve per file. datanodes does
 *                this: the widget is invisible and auto-solves in a real
 *                browser, which is why it feels like a plain "Free Download"
 *                button, but no cookie substitutes for the token it produces.
 *
 * @returns {Promise<boolean>} whether to re-resolve after the user returns
 */
async function offerClearance(blocked) {
  const captcha = blocked.filter((r) => r.kind === 'captcha');
  const clearance = blocked.filter((r) => r.kind !== 'captcha');
  let retry = false;

  if (clearance.length) {
    const hostList = [...new Set(clearance.map((r) => naming.hostOf(r.resolvedUrl)))];
    log.blank();
    log.warn(`${clearance.length} link(s) need a Cloudflare clearance for: ${hostList.join(', ')}`);
    log.info(log.paint.dim(
      '  Chrome needs a fresh cf_clearance cookie. Opening a file page (not the\n' +
      '  front page, which never challenges) mints one for the whole host.'
    ));
    if (await prompt.confirm('Open a file page in Chrome now?', true)) {
      // One page per host is enough to earn the cookie.
      openInChrome(hostList.map((h) => clearance.find((r) => naming.hostOf(r.resolvedUrl) === h).resolvedUrl),
                   'file page(s)');
      await prompt.text('Press Enter once the page has finished loading', '');
      for (const h of hostList) chrome.forget(h);
      retry = true;
    }
  }

  if (captcha.length) {
    log.blank();
    log.warn(`${captcha.length} link(s) cannot be resolved from the CLI -- ` +
             `${captcha[0].note}.`);
    log.info(log.paint.dim(
      '  The widget is invisible and solves itself in a real browser, so the page\n' +
      '  just shows a Free Download button and starts after a short counter. That\n' +
      '  token cannot be produced outside the browser, so these will not enter the\n' +
      "  queue built here -- with ABDM's extension installed, the browser hands the\n" +
      '  download straight to ABDM instead.'
    ));
    if (await prompt.confirm(`Open ${Math.min(captcha.length, MAX_TABS)} link(s) in Chrome now?`, false)) {
      openInChrome(captcha.map((r) => r.resolvedUrl), 'download page(s)');
      log.info(log.paint.dim('  Click the download button, then click it again once the ad tab closes.'));
    }
  }

  return retry;
}

// -- stage 4/5: plan and apply ----------------------------------------------

async function planQueue(cfg, addable, opts) {
  const existing = await abdm.listQueues(cfg);

  if (opts.queueId != null) {
    const found = existing.find((q) => q.id === opts.queueId);
    if (!found) throw new Error(`queue ${opts.queueId} does not exist in ABDM`);
    log.info(`Queue: ${log.paint.bold(found.name)} ${log.paint.dim('(id ' + found.id + ', existing)')}`);
    return { id: found.id, name: found.name, created: false };
  }

  const suggested = opts.queueName ||
    naming.deriveQueueName(addable, { title: addable[0] && addable[0].title });
  const name = opts.queueName || (await prompt.text('Queue name', suggested));

  const match = existing.find((q) => q.name.toLowerCase() === name.toLowerCase());
  if (match) {
    log.info(`Queue: ${log.paint.bold(match.name)} ${log.paint.dim('(id ' + match.id + ', reusing existing)')}`);
    return { id: match.id, name: match.name, created: false };
  }
  return { id: null, name, created: true };
}

async function ensureQueue(cfg, queue, opts) {
  if (!queue.created) return queue;

  log.blank();
  log.warn(
    'ABDM has no API for creating queues, so the queue file is written directly.\n' +
    '        That needs ABDM to be stopped and restarted (in-progress downloads pause).'
  );
  if (!(await prompt.confirm(`Create queue "${queue.name}" and restart ABDM?`, true))) {
    throw new Error('queue creation declined');
  }

  const res = await abdm.createQueue(cfg, queue.name, opts);
  if (!res.ok) throw new Error('could not create queue: ' + res.error);
  log.ok(`queue "${queue.name}" created (id ${res.id})`);
  return { id: res.id, name: queue.name, created: true };
}

async function planFolder(cfg, queueName, opts) {
  if (opts.folder) return path.resolve(opts.folder.replace(/^~(?=\/|$)/, os.homedir()));
  const def = path.join(cfg.defaultFolder, naming.sanitizePath(queueName));
  const answer = await prompt.text('Download folder', def);
  return path.resolve(answer.replace(/^~(?=\/|$)/, os.homedir()));
}

function extraHeaders(opts) {
  const out = {};
  for (const h of opts.headers) {
    const idx = h.indexOf(':');
    if (idx > 0) out[h.slice(0, idx).trim()] = h.slice(idx + 1).trim();
  }
  return out;
}

async function addAll(cfg, items, queue, folder, opts) {
  const extra = extraHeaders(opts);
  let added = 0;
  const failures = [];

  const results = await pool(items, Math.min(opts.concurrency, 8), (item) =>
    abdm.addDownload(cfg, item.resolvedUrl, {
      name: item.name,
      folder,
      downloadPage: item.downloadPage,
      queueId: queue.id,
      start: opts.start,
      startQueue: opts.startQueue,
      headers: Object.assign({}, item.headers, extra),
    })
  );

  results.forEach((r, i) => {
    if (r.ok) { added++; log.info(`  ${log.paint.green('+')} ${items[i].name}`); }
    else failures.push({ item: items[i], error: r.error });
  });
  for (const f of failures) {
    log.err(`  ${f.item.name}: ${f.error}`);
  }
  return { added, failed: failures.length };
}

// -- main -------------------------------------------------------------------

async function main() {
  const opts = parseArgs(process.argv.slice(2));
  log.setVerbose(opts.verbose);
  prompt.configure(opts);
  doh.configure(opts);

  if (opts.urls.includes('-')) {
    opts.urls = opts.urls.filter((u) => u !== '-').concat(readStdinUrls());
  }
  // A bare path is a convenience for the `file` source.
  opts.urls = opts.urls.map((u) => {
    if (/^[a-z][a-z0-9+.-]*:/i.test(u)) return u;
    return fs.existsSync(u) ? 'file://' + path.resolve(u) : u;
  });
  if (!opts.urls.length) {
    process.stderr.write(help());
    process.exit(1);
  }

  // 1-2. collect and filter.
  const collected = await collectLinks(opts);
  if (!collected.length) {
    log.err('no links found in any source.');
    process.exit(1);
  }
  const links = applyFilters(collected, opts);
  if (!links.length) {
    log.err(`no links matched the filters (${collected.length} before filtering).`);
    process.exit(1);
  }

  if (opts.list) {
    for (const l of links) process.stdout.write(l.url + '\n');
    log.info(`\n${links.length} link(s).`);
    return;
  }

  // --open-site: open one file page per host and stop. It must be a file page,
  // not the host root -- Cloudflare does not challenge on the front page, so
  // opening that mints no clearance cookie at all.
  if (opts.openSite) {
    const perHost = new Map();
    for (const l of links) {
      const h = naming.hostOf(l.url);
      if (!perHost.has(h)) perHost.set(h, l.url);
    }
    openInChrome([...perHost.values()], 'file page(s)');
    log.info('\nLet each page finish loading, then re-run without --open-site.');
    return;
  }

  // 3. resolve.
  log.blank();
  let results = await resolveAll(links, opts);
  reportResolution(results);

  let addable = results.filter((r) => r.status === 'direct' || r.status === 'passthrough');
  let blocked = results.filter((r) => r.status === 'challenge');

  // Earning a clearance in Chrome only helps if the blocked links are then
  // tried again, so re-resolve them in place once the user comes back.
  let rounds = 0;
  while (blocked.length && prompt.interactive() && rounds < 2) {
    rounds++;
    if (!(await offerClearance(blocked))) break;

    log.blank();
    log.step('resolve', `retrying ${blocked.length} link(s) with the new cookies`);
    const retried = await resolveAll(blocked, opts);
    reportResolution(retried);

    const byUrl = new Map(retried.map((r) => [r.url, r]));
    results = results.map((r) => byUrl.get(r.url) || r);
    addable = results.filter((r) => r.status === 'direct' || r.status === 'passthrough');
    blocked = results.filter((r) => r.status === 'challenge');
  }

  if (blocked.length && !prompt.interactive()) {
    const captcha = blocked.filter((r) => r.kind === 'captcha');
    if (captcha.length) {
      log.warn(`${captcha.length} link(s) need a per-file captcha solved in Chrome ` +
               `(${captcha[0].note}); they cannot be queued from the CLI.`);
    }
    if (captcha.length < blocked.length) {
      log.warn(`${blocked.length - captcha.length} link(s) blocked by Cloudflare -- run with ` +
               '--open-site, pass the challenge in Chrome, then re-run.');
    }
  }

  if (!addable.length) {
    log.err('nothing left to add.');
    process.exit(1);
  }

  // 4. plan.
  log.blank();
  const totalSize = addable.reduce((n, r) => n + (r.size || 0), 0);
  log.info(
    `${log.paint.bold(String(addable.length))} file(s) ready` +
    (totalSize ? `, ${naming.formatSize(totalSize)} total` : '') +
    (results.length !== addable.length
      ? log.paint.dim(`  (${results.length - addable.length} skipped)`) : '')
  );
  log.blank();

  // Some hosts sign their direct links with a short expiry, so a queue left
  // paused overnight would wake up to a set of 404s. Push towards starting now.
  const ephemeral = addable.filter((r) => r.ephemeral);
  if (ephemeral.length && !opts.start && !opts.startQueue) {
    log.warn(
      `${ephemeral.length} link(s) expire a few minutes after being resolved.\n` +
      '        Queued-but-paused downloads will 404; start them now, or re-run\n' +
      '        this command later to mint fresh links.'
    );
    if (await prompt.confirm('Start the queue immediately after adding?', true)) {
      opts.startQueue = true;
      opts.start = true;
    }
    log.blank();
  }

  const cfg = abdm.readConfig({});
  if (!(await abdm.ensureRunning(cfg, opts))) {
    log.err(
      'AB Download Manager is not reachable on 127.0.0.1:' + cfg.port + '.\n' +
      '       Start ABDM and enable Settings > Integration > Enable API.'
    );
    process.exit(1);
  }

  let queue = await planQueue(cfg, addable, opts);
  const folder = await planFolder(cfg, queue.name, opts);

  if (opts.dryRun) {
    log.blank();
    log.info(log.paint.bold('Dry run -- nothing was added.'));
    log.info(`  queue:  ${queue.name}${queue.created ? ' (would be created)' : ` (id ${queue.id})`}`);
    log.info(`  folder: ${folder}`);
    addable.forEach((r, i) => {
      log.info(`  ${String(i + 1).padStart(3)}. ${r.name}`);
      log.info(log.paint.dim(`       ${r.resolvedUrl.slice(0, 120)}`));
    });
    return;
  }

  // 5. apply.
  queue = await ensureQueue(cfg, queue, opts);
  try {
    fs.mkdirSync(folder, { recursive: true });
  } catch (e) {
    log.warn(`could not create ${folder}: ${e.message}`);
  }

  log.blank();
  log.step('add', `${addable.length} download(s) -> queue "${queue.name}" in ${folder}`);
  const { added, failed } = await addAll(cfg, addable, queue, folder, opts);

  log.blank();
  log.ok(`${added} added${failed ? `, ${failed} failed` : ''} to queue "${queue.name}".`);
  if (!opts.start && !opts.startQueue) {
    log.info(log.paint.dim('  Downloads are queued but paused -- start the queue in ABDM, ' +
                           'or re-run with --start-queue.'));
  }
  if (failed) process.exitCode = 1;
}

module.exports = { main, help, parseArgs };
