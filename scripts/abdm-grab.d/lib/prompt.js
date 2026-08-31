'use strict';
/*
 * Interactive prompts.
 *
 * Reads from /dev/tty rather than stdin so prompting still works when the tool
 * is fed URLs on a pipe (`cat urls.txt | abdm-grab -`). When there is no tty,
 * or --yes was passed, every prompt silently takes its default -- so the same
 * code path works in a script.
 */

const fs = require('fs');
const readline = require('readline');
const { paint } = require('./log');

let auto = false;              // --yes: accept defaults without asking
let tty = null;                // lazily opened { input, output }

function configure(opts) { auto = !!opts.yes; }

function openTty() {
  if (tty !== null) return tty;
  try {
    // openSync fails synchronously with ENXIO when there is no controlling
    // terminal (cron, a pipeline, a detached process). createReadStream would
    // instead emit that error asynchronously and crash past any try/catch.
    const input = fs.createReadStream(null, { fd: fs.openSync('/dev/tty', 'r') });
    const output = fs.createWriteStream(null, { fd: fs.openSync('/dev/tty', 'w') });
    input.on('error', () => {});
    output.on('error', () => {});
    tty = { input, output };
  } catch (e) {
    tty = false;                // no controlling terminal
  }
  return tty;
}

function interactive() {
  return !auto && openTty() !== false;
}

function ask(question) {
  const t = openTty();
  if (t === false) return Promise.resolve('');
  return new Promise((resolve) => {
    const rl = readline.createInterface({ input: t.input, output: t.output, terminal: true });
    rl.question(question, (answer) => { rl.close(); resolve(answer); });
  });
}

/**
 * Free-text prompt with a default shown in brackets.
 * @param {string} label
 * @param {string} def   value used on empty input, --yes, or no tty
 */
async function text(label, def) {
  if (!interactive()) {
    process.stderr.write(`${label}: ${paint.bold(def)} ${paint.dim('(default)')}\n`);
    return def;
  }
  const suffix = def ? ` ${paint.dim('[')}${paint.bold(def)}${paint.dim(']')}` : '';
  const answer = (await ask(`${label}${suffix}: `)).trim();
  return answer || def;
}

/** Yes/no prompt. `def` is the answer used non-interactively. */
async function confirm(label, def) {
  if (!interactive()) {
    process.stderr.write(`${label}: ${paint.bold(def ? 'yes' : 'no')} ${paint.dim('(default)')}\n`);
    return def;
  }
  const hint = def ? 'Y/n' : 'y/N';
  for (;;) {
    const answer = (await ask(`${label} ${paint.dim('[' + hint + ']')} `)).trim().toLowerCase();
    if (!answer) return def;
    if (/^(y|yes)$/.test(answer)) return true;
    if (/^(n|no)$/.test(answer)) return false;
  }
}

/**
 * Pick one of a list.
 * @param {string} label
 * @param {{label: string, value: any, hint?: string}[]} choices
 * @param {number} defIndex
 */
async function select(label, choices, defIndex) {
  defIndex = defIndex || 0;
  if (!interactive()) {
    process.stderr.write(
      `${label}: ${paint.bold(choices[defIndex].label)} ${paint.dim('(default)')}\n`
    );
    return choices[defIndex].value;
  }
  const out = openTty().output;
  out.write(label + '\n');
  choices.forEach((c, i) => {
    const marker = i === defIndex ? paint.cyan('>') : ' ';
    const hint = c.hint ? paint.dim('  ' + c.hint) : '';
    out.write(`  ${marker} ${paint.bold(String(i + 1))}. ${c.label}${hint}\n`);
  });
  for (;;) {
    const answer = (await ask(`  choice ${paint.dim('[' + (defIndex + 1) + ']')}: `)).trim();
    if (!answer) return choices[defIndex].value;
    const n = parseInt(answer, 10);
    if (n >= 1 && n <= choices.length) return choices[n - 1].value;
  }
}

function close() {
  if (tty && tty !== false) {
    try { tty.input.destroy(); } catch (e) { /* already closed */ }
    try { tty.output.end(); } catch (e) { /* already closed */ }
  }
}

module.exports = { configure, text, confirm, select, interactive, close };
