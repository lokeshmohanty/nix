'use strict';
/*
 * AB Download Manager client.
 *
 * Downloads are added over the local HTTP API (Settings > Integration > Enable
 * API). The API is required rather than optional: `abdownloadmanager-cli
 * download add` splits --header values on ':' and '=', which corrupts Cookie
 * headers, and cookies are exactly what Cloudflare-protected hosts need. The
 * CLI is still used for the one thing the API cannot do -- stopping and
 * starting the app.
 *
 * Queue creation likewise has no API endpoint (probed: /queue/add, /queues/add,
 * /add-queue, /create-queue all 404). Queues live as JSON files under
 * ~/.abdm/config/download_db/queues/. ABDM reads them at startup and rewrites
 * them on exit, so a new queue file must be written while the app is STOPPED --
 * otherwise the running instance overwrites it on shutdown.
 */

const http = require('http');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');
const log = require('./log');

const ABDM_HOME = path.join(os.homedir(), '.abdm');
const SETTINGS = path.join(ABDM_HOME, 'config', 'appSettings.json');
const QUEUES_DIR = path.join(ABDM_HOME, 'config', 'download_db', 'queues');

/** Read port/auth/default-folder out of ABDM's own settings file. */
function readConfig(overrides) {
  overrides = overrides || {};
  let settings = {};
  try {
    settings = JSON.parse(fs.readFileSync(SETTINGS, 'utf8'));
  } catch (e) {
    log.debug('could not read ' + SETTINGS + ': ' + e.message);
  }
  return {
    port: overrides.port || settings.apiPort || 15151,
    authKey: overrides.key || (settings.apiAuthEnabled ? settings.apiAuthKey : null),
    apiEnabled: settings.apiEnabled !== false,
    defaultFolder: settings.defaultDownloadFolder || path.join(os.homedir(), 'Downloads'),
  };
}

function apiRequest(cfg, method, apiPath, body) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : null;
    const headers = { 'Content-Type': 'application/json' };
    if (data) headers['Content-Length'] = Buffer.byteLength(data);
    if (cfg.authKey) headers.Authorization = 'Bearer ' + cfg.authKey;

    const req = http.request(
      { hostname: '127.0.0.1', port: cfg.port, path: apiPath, method, headers, timeout: 20000 },
      (res) => {
        const chunks = [];
        res.on('data', (c) => chunks.push(c));
        res.on('end', () =>
          resolve({ status: res.statusCode, body: Buffer.concat(chunks).toString('utf8') })
        );
      }
    );
    req.on('error', reject);
    req.on('timeout', () => req.destroy(new Error('ABDM API request timed out')));
    if (data) req.write(data);
    req.end();
  });
}

async function ping(cfg) {
  try {
    const res = await apiRequest(cfg, 'POST', '/ping');
    return res.status === 200 && res.body.trim() === 'pong';
  } catch (e) {
    return false;
  }
}

async function listQueues(cfg) {
  try {
    const res = await apiRequest(cfg, 'GET', '/queues');
    if (res.status === 200) return JSON.parse(res.body);
  } catch (e) {
    log.debug('listQueues failed: ' + e.message);
  }
  return [];
}

/** Add one download. Headers are passed as an object; the API preserves them. */
async function addDownload(cfg, link, opts) {
  const task = {
    downloadSource: {
      type: 'http',
      link,
      headers: opts.headers || {},
      suggestedName: opts.name || '',
      downloadPage: opts.downloadPage || '',
    },
    name: opts.name || '',
    folder: opts.folder || '',
    queueId: opts.queueId != null ? opts.queueId : 0,
    startDownload: !!opts.start,
    startQueue: !!opts.startQueue,
  };
  if (opts.categoryId != null) task.categoryId = opts.categoryId;

  try {
    const res = await apiRequest(cfg, 'POST', '/start-headless-download', task);
    if (res.status >= 200 && res.status < 300) return { ok: true, link, response: res.body.trim() };
    return { ok: false, link, error: 'HTTP ' + res.status + ': ' + res.body.trim().slice(0, 200) };
  } catch (e) {
    return { ok: false, link, error: e.message };
  }
}

// -- app lifecycle ----------------------------------------------------------

function findCli(override) {
  if (override) return override;
  const candidates = [
    path.join(os.homedir(), '.nix-profile/bin/abdownloadmanager-cli'),
    '/run/current-system/sw/bin/abdownloadmanager-cli',
    '/usr/bin/abdownloadmanager-cli',
    '/usr/local/bin/abdownloadmanager-cli',
  ];
  for (const c of candidates) if (fs.existsSync(c)) return c;
  const which = spawnSync('sh', ['-c', 'command -v abdownloadmanager-cli'], { encoding: 'utf8' });
  return (which.stdout || '').trim() || null;
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function waitForApi(cfg, timeoutMs) {
  const deadline = Date.now() + (timeoutMs || 45000);
  while (Date.now() < deadline) {
    if (await ping(cfg)) return true;
    await sleep(500);
  }
  return false;
}

async function stopApp(cli) {
  spawnSync(cli, ['gui', 'exit'], { encoding: 'utf8', timeout: 15000 });
  // Give the app time to flush its download DB and queue files before we touch them.
  await sleep(2500);
}

function startApp(cli) {
  const r = spawnSync(cli, ['gui', 'start-if-not-started'], { encoding: 'utf8', timeout: 20000 });
  return r.status === 0;
}

// -- queues -----------------------------------------------------------------

/** Queue ids currently on disk. */
function queueIdsOnDisk() {
  try {
    return fs.readdirSync(QUEUES_DIR)
      .map((f) => parseInt(path.basename(f, '.json'), 10))
      .filter((n) => Number.isInteger(n));
  } catch (e) {
    return [];
  }
}

function nextQueueId() {
  const ids = queueIdsOnDisk();
  return ids.length ? Math.max(...ids) + 1 : 1;
}

function writeQueueFile(id, name) {
  fs.mkdirSync(QUEUES_DIR, { recursive: true });
  const queue = {
    id,
    name,
    maxConcurrent: 2,
    queueItems: [],
    scheduledTimes: {
      daysOfWeek: ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'],
      startTime: '02:30',
      endTime: '07:30',
      enabledStartTime: false,
      enabledEndTime: false,
    },
    stopQueueOnEmpty: false,
  };
  fs.writeFileSync(path.join(QUEUES_DIR, id + '.json'), JSON.stringify(queue, null, 4));
}

/**
 * Create a queue and make the running app aware of it.
 *
 * ABDM rewrites its queue files on exit, so the file is written while the app
 * is stopped, then the app is restarted to load it.
 *
 * @returns {Promise<{ok: boolean, id?: number, error?: string}>}
 */
async function createQueue(cfg, name, opts) {
  opts = opts || {};
  const cli = findCli(opts.cli);
  if (!cli) {
    return {
      ok: false,
      error: 'abdownloadmanager-cli not found -- it is needed to restart ABDM so it ' +
             'picks up the new queue. Create the queue in the ABDM UI instead, then ' +
             'pass --queue <id>.',
    };
  }

  const id = nextQueueId();
  const wasRunning = await ping(cfg);

  if (wasRunning) {
    log.step('queue', 'stopping ABDM so it does not overwrite the new queue file...');
    await stopApp(cli);
  }

  try {
    writeQueueFile(id, name);
  } catch (e) {
    if (wasRunning) startApp(cli);
    return { ok: false, error: 'could not write queue file: ' + e.message };
  }

  log.step('queue', 'starting ABDM...');
  startApp(cli);
  if (!(await waitForApi(cfg, 45000))) {
    return { ok: false, error: 'ABDM did not come back up within 45s' };
  }

  // Confirm the app actually loaded it, rather than trusting the file write.
  const queues = await listQueues(cfg);
  if (!queues.some((q) => q.id === id)) {
    return { ok: false, error: 'ABDM restarted but queue ' + id + ' is not registered' };
  }
  return { ok: true, id };
}

/** Ensure the app is running and the API answers. */
async function ensureRunning(cfg, opts) {
  if (await ping(cfg)) return true;
  const cli = findCli((opts || {}).cli);
  if (!cli) return false;
  log.step('abdm', 'ABDM is not responding -- starting it...');
  startApp(cli);
  return waitForApi(cfg, 45000);
}

module.exports = {
  readConfig, ping, listQueues, addDownload, createQueue, ensureRunning,
  findCli, nextQueueId, waitForApi, SETTINGS, QUEUES_DIR,
};
