# Preferences — Lokesh Mohanty

## Who

- Lokesh Mohanty — PhD researcher (life-long learning for planning in autonomous systems; thesis workspace at `~/Documents/Research/Thesis`) and engineer at Zenteiq (`~/Projects/zenteiq`, work email `lokeshm@iisc.ac.in`, `lokeshmohanty@zenteiq.com`).
- Solo on research judgment; agents propose, validators gate, Lokesh judges.

## Environment (NixOS)

- OS-level dependencies are managed with NixOS + nix-flakes at `~/.nix`. Never suggest apt/dnf/pacman.
- Project-level OS deps: `shell.nix` at the project root.
- Language deps use native package managers:
  - Python: `uv` (preferred) over pip.
  - Node.js: `npm` or `pnpm` — ask if unclear.
  - Others: their respective package managers.
- The agent harness itself is tracked in `~/.nix/config/agentic-harness/` and applied via home-manager activations (`~/.nix/home/activations.nix`). Change it there, then apply; never hand-edit only the live symlink targets.

## Working style

- Honest framing beats impressive framing; surface self-caught corrections, don't bury them.
- Exhaustive clarifying questions before large generation; phased delivery with review checkpoints.
- Model routing (see `context-manager` skill): frontier model for theory/skill-authoring/research judgment; mid-tier for setup/drafting; small/local (pi with Gemma-4-31B) for routine tasks and reading `docs/`.
- Codex model routing (2026-09-23): use `gpt-6-sol` only for planning; use `gpt-6-luna` to execute simpler tasks. This overrides the older tier examples above for Codex.
- Keep documentation plain markdown so local models (pi) can answer from it without special tooling.

## Tooling defaults

- Library/framework questions: context7 (`ctx7` CLI or MCP) before web search.
- Code-structure questions in the big zenteiq repos: gortex (tracked there only). Elsewhere: read `docs/` or run GitNexus on demand (`npx gitnexus@latest analyze`).
- Browser automation: playwright plugin / chrome-devtools-axi.
- **Console output stays visible.** A long-running command shows progress on the terminal by default, and capturing output to a log means `tee`, never a redirect that swallows it — a silent process is indistinguishable from a hung one. (2026-08-18: a 1M-step training run printed nothing for hours.)
