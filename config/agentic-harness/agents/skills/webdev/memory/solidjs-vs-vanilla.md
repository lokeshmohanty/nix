---
description: >-
  Why converting personal/games from raw HTML/CSS/JS to SolidJS was rejected
  (2026-08-10, re-asked and re-confirmed 2026-08-27), what was built instead,
  and the reusable checklist for any framework-migration question.
metadata:
  type: decision
  tags: [solidjs, framework, migration, build-step, vanilla-js]
---

# SolidJS vs vanilla — the games repo verdict (2026-08-10, held 2026-08-27)

**Verdict: do not convert.** Asked to weigh merits/demerits for
`~/Projects/personal/games` (4 canvas games + portal, 5,570 lines, zero deps,
no build step, deployed to GitHub Pages as raw files).

**Lokesh asked again on 2026-08-27** — "would solidjs be a better option than
raw js?" — mid-way through a build, not as an idle question. Expect it to come
back; answer it with the measurement, not the verdict. The ratio had moved
*away* from a framework: the session added ~700 lines of pure logic
(`lib/secrets.js`, `lib/rounds.js`), so the reactive share fell to ~20% of 7,600
lines. Same answer, better number.

## The measurement that decided it

Both times, and the second column is the one to quote now.

| Layer | 2026-08-10 | 2026-08-27 | Framework helps? |
|---|---|---|---|
| P2P + codecs + the new plumbing (`net`, `qr`, `qr-decode`, `secrets`, `rounds`) | ~2,350 | ~3,214 | No — pure logic, barely any DOM |
| Canvas game loops | ~1,800 | ~2,833 (6 games) | No — `rAF` + `ctx` draw calls |
| DOM chrome (`lobby`, `party`, `games`, `pwa`) + per-game HUD | ~900 | ~1,566 | **Yes** |
| CSS + portal | ~500 | ~500 | No |

Roughly **15%**, then **~20%**, of the code would benefit. That number, not
taste, is the argument — and note which way it moved: adding two pure-logic
modules pushed the reactive share *down* even as the DOM chrome grew. A repo
that keeps growing its logic layer keeps getting a worse case for a framework.

## Genuine merits found

- `lib/lobby.js` is a hand-rolled reactive state machine — `stage.replaceChildren()`
  at 5 sites plus a manual `setStatus()` pub/sub, over host/guest/spectator ×
  connecting/connected/started. Exactly what fine-grained reactivity replaces,
  and the most bug-prone file in the repo.
- `draw-guess.html:492-536` rebuilds the whole HUD every tick (timer, score
  pills, word hint) via `replaceChildren()` + per-branch `.style.color` /
  `.style.textShadow`. Solid would touch one text node.
- Overlay/HUD/portal-link chrome is copy-pasted across four games.

## Demerits that outweighed them

1. **Breaks `file://`.** `lib/net.js:22` and `lib/lobby.js:20` both state the
   scripts are deliberately classic (not ESM) so `file://` works with no
   server, and `docs/index.md` lists `file://` as a *verified* way to play two
   peers locally. JSX needs a compiler and emits ESM, which browsers refuse
   over `file://` (opaque origin → CORS). Escapable only by bundling to an
   IIFE global — fighting the toolchain from day one.
2. **Build step vs `path: '.'` deploy.** `.github/workflows/deploy.yml` uploads
   the repository as-is. A framework forces a build job, a `dist/`, and
   `.gitignore` churn to serve four static pages.
3. **Contradicts the repo's thesis.** It hand-rolls a QR *encoder*, a QR
   *decoder* (892 lines) and a WebRTC mesh layer. Stopping the
   own-your-stack instinct at the DOM shell is arbitrary. (Not a
   no-third-party-services violation — Solid is compile-time, not a network
   service — but the same instinct.)
4. **`scripts/preview.mjs`** drives game HTML headless to record portal gifs;
   it would need to target build output, adding a stale-build failure mode to
   the gif pipeline.
5. Single-file games stop being single-file — `connect4.html` is currently one
   readable, shareable file.

## The counter-offer — half of it now exists

`lib/ui.js` **was built on 2026-08-27** (`NeonArcade.gameShell`): the duplicated
stage/HUD/overlay chrome, as plain factory functions over plain DOM. The one
idea borrowed from Solid is that `setHud` **updates text nodes in place** rather
than rebuilding the row — that was the concrete Draw & Guess complaint above.

The trigger mattered: it stopped being a tidy-up and became leverage at the
moment three more games were about to be written against the same chrome. Do
not propose it as standalone cleanup; propose it when the next game is queued.

Two things it had to learn, both invisible until asserted at 390x844:

- The stage must reserve **52px of top padding** for the fixed `.portal-link`
  ("← ALL GAMES"). Vertically centring without it puts the status line
  underneath the link, and it reads as a text bug rather than a layout one.
- The child that absorbs leftover height takes a `.g-fill` class, **not**
  `height: 100%` — the latter overflows the stage and pushes the status line off
  the top.

`lib/reactive.js` (`createSignal` / `createEffect`) was **not** built and has
not been needed. Do not offer it unprompted; the factory functions covered the
complaint on their own.

## Reusable checklist

Before recommending any framework migration:

1. Split LOC into DOM chrome / render loop / pure logic. Quote the ratio.
2. Grep the repo and its docs for `file://`, "no build", "no dependencies",
   "single file" — stated constraints outrank general best practice.
3. Read the deploy workflow. `path: '.'` means the build step is a new moving
   part, not a free one.
4. Find scripts that consume source files directly (preview recorders, e2e,
   screenshot tools) — each is migration work nobody budgets for.
5. Ask whether the framework's *core idea* can be had without its *toolchain*.
6. Present the merits honestly and first; a recommendation that only lists
   costs reads as reflexive conservatism and gets discounted.
7. If the repo already rejected this once, **re-measure rather than quoting the
   old verdict.** The numbers move, and a re-asked question deserves a current
   answer — not "we decided this in August".

See also the `ui` skill for the visual conventions that survive either choice.
