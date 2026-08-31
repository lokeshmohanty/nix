'use strict';
/* Logging. Everything goes to stderr so stdout stays a clean data channel
 * (`--list` prints URLs, `--json` prints a report). */

const useColor = process.stderr.isTTY && !process.env.NO_COLOR;
const c = (code) => (s) => (useColor ? `\x1b[${code}m${s}\x1b[0m` : String(s));

const paint = {
  dim: c('2'),
  bold: c('1'),
  red: c('31'),
  green: c('32'),
  yellow: c('33'),
  blue: c('34'),
  cyan: c('36'),
};

let verbose = false;
const setVerbose = (v) => { verbose = !!v; };

const write = (s) => process.stderr.write(s + '\n');
const tag = (t, colour) => paint.dim('[') + colour(t) + paint.dim(']');

module.exports = {
  paint,
  setVerbose,
  isVerbose: () => verbose,
  /** Section header, e.g. log.step('source', 'privatebin …'). */
  step: (t, msg) => write(`${tag(t, paint.cyan)} ${msg}`),
  ok: (msg) => write(`${paint.green('✓')} ${msg}`),
  warn: (msg) => write(`${tag('warn', paint.yellow)} ${msg}`),
  err: (msg) => write(`${tag('error', paint.red)} ${msg}`),
  info: (msg) => write(msg),
  /** Only shown with --verbose; for per-request / per-strategy noise. */
  debug: (msg) => { if (verbose) write(paint.dim('  · ' + msg)); },
  blank: () => write(''),
};
