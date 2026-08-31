# ~/.nix — Documentation

*Last synced: 2026-07-21 (docs-sync). Entry point — any LLM should answer
questions about this repo from this folder plus the linked pages.*

## Contents

- [architecture.md](architecture.md) — how the flake is wired: flake-parts,
  hostlib, module toggles, variables, activations, custom packages.
- [how-to/install-ubuntu.md](how-to/install-ubuntu.md) — bootstrap Nix and apply
  the portable server Home Manager profile on a fresh Ubuntu machine.
- [how-to/abdm-grab.md](how-to/abdm-grab.md) — extract download links and queue
  them in AB Download Manager; sources/hosts plugin layout.
- [decisions.md](decisions.md) — dated rationale for significant configuration
  decisions.
- Harness documentation lives at `../config/agentic-harness/agents/docs/`
  (layout, per-harness matrix, hooks, tools) — linked, not duplicated.

## How-to (verified commands)

| Task | Command |
|---|---|
| Apply system config | `sudo nixos-rebuild switch --flake ~/.nix#sudarshan` (or `nh os switch . -c sudarshan`) |
| Apply home config | `home-manager switch --flake ~/.nix#lokesh@sudarshan` |
| Install on Ubuntu | `~/.nix/scripts/install.sh` (see the Ubuntu install guide) |
| Queue download links into ABDM | `abdm-grab <url>` — see the abdm-grab guide |
| Update inputs | `nix flake update` (in `~/.nix`) |
| Syntax-check a module | `nix-instantiate --parse <file.nix>` |
| Format | `nix fmt` (formatter: nixfmt) |
| Build a custom package | `nix build ~/.nix#<name>` / run: `nix run ~/.nix#<name>` (pkgs/: nvim, ghost-*, axi-tools) |
| Non-nix setup (fish plugins, wallpapers) | `just <recipe>` — see `Justfile` |
| Scaffold agent harness in a repo | `harness-init [dir]` (from `config/agentic-harness/bin/`) |
| Record the screen / turn a clip into a gif | `screen-rec` (from `config/agentic-harness/bin/`; run bare for state + commands). In pi: `/record <what you want>` |

Fresh install: boot NixOS media → `nixos-install --flake .#<hostname>`; details in `README.md`.

## Conventions

- New home module: add file under `home/`, import in `home/default.nix`, gate
  behind `options.modules.<name>.enable` if optional, toggle per host in
  `hosts/<host>/default.nix`.
- App configs that tools rewrite at runtime live in `config/` and are symlinked
  by `home/activations.nix` (always `ln -sfn`).
- Secrets never enter this repo (they live in machine-local dotfiles).

## Honest gaps

- No per-host docs (bhaskara/bose differences undocumented here — read
  `hosts/<host>/`).
- `system/` modules not individually documented; names are self-describing.
