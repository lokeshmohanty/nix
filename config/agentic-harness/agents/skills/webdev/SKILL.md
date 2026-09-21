---
name: webdev
description: >-
  Front-end architecture decisions for web projects — whether to adopt a
  framework, what a build step costs, and when vanilla DOM is the right answer.
  Use when considering a rewrite or migration (React/Solid/Svelte/Vue), when
  adding a bundler or build step to a project that has none, when weighing a
  dependency against hand-rolled code, or when someone asks "should we convert
  this to <framework>".
---

# Web Dev

Architecture decisions for browser front-ends. Visual/typographic conventions
live in the `ui` skill — this one is about structure, dependencies and build.

## Working rules

1. **Measure the reactive surface before proposing a framework.** A framework
   pays for itself in proportion to DOM-derived-from-state code, not total
   LOC. Split the codebase into (a) DOM chrome, (b) canvas/WebGL render loops,
   (c) pure logic. Only (a) benefits. Quote the ratio in the recommendation —
   "~15% of the code" ends the argument faster than any opinion.

2. **Canvas is a framework dead zone.** Inside a `requestAnimationFrame` loop
   the framework contributes nothing: the draw calls are identical. Games,
   visualisations and editors are usually a thin reactive shell around a large
   non-reactive core.

3. **Name what the build step breaks, specifically.** "Adds complexity" is
   ignorable; "breaks `file://`, which `docs/` lists as a supported way to
   run this" is not. Check for: `file://` support, zero-dep deploy
   (`upload-pages-artifact path: '.'`), single-file-shareable pages, and any
   script that drives source files directly (preview recorders, e2e).

4. **Separate the idea from the toolchain.** Fine-grained signals are ~40 lines
   of vanilla JS. JSX is the part that forces a compiler. Offer the primitive
   without the build before offering the framework — it usually captures most
   of the benefit at none of the cost.

5. **Respect an evident zero-dependency thesis.** If a repo hand-rolls its own
   QR codec and WebRTC layer, adding a framework for the DOM shell is
   inconsistent, not pragmatic. Say so and let the owner overrule it.

## Memory

- `memory/solidjs-vs-vanilla.md` — the `personal/games` analysis (2026-08-10,
  re-asked and re-confirmed 2026-08-27): the measured split both times, why the
  answer was "don't convert", what `lib/ui.js` was built instead, and the
  reusable decision checklist. **Re-measure before answering a repeat ask.**
