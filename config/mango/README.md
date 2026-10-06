---
title: Mango Configuration
---

# Mango (`config/mango/`)

Mango setup that mirrors `config/hypr/*.conf` in structure and follows
`config/niri/config.kdl` in values. Entry point is `config.conf`
(mango auto-loads `~/.config/mango/config.conf`, which is symlinked here
by `home/activations.nix`).

| file | mirrors | contains (from niri) |
|---|---|---|
| `config.conf` | `hyprland.conf` | `source=` lines only |
| `env.conf` | `hypr/env.conf` | env vars |
| `appearance.conf` | `hypr/appearance.conf` | gaps, border/focus colors, radius, opacity, blur, shadows, animations, scroller/tile/dwindle defaults, overview, misc |
| `input.conf` | — (hypr keeps input in `appearance.conf`) | keyboard repeat/numlock/xkb, trackpad, mouse |
| `monitors.conf` | `hypr/monitors.conf` | `monitorrule` per output |
| `workspaces.conf` | `hypr/workspaces.conf` | `tagrule` per tag |
| `windowrules.conf` | `hypr/windowrules.conf` | `windowrule` + `layerrule` |
| `binds.conf` | `hypr/binds.conf` | all binds |
| `autostart.conf` | `hypr/autostart.conf` | `exec-once` lines |

No `variables.conf`: mango 0.16.3 has no `var=` support (added upstream
later), so commands are inlined in `binds.conf`.

## Useful commands

- Validate without starting: `mango -c ~/.config/mango/config.conf -p`
- Reload a running mango: `SUPER+SHIFT+slash`

## Porting notes (niri -> mango)

- Workspaces -> fixed tags 1–9 (`view`/`tag`); niri's dynamic empty
  workspaces and `focus-workspace-previous` map to `view,-1,0` for last.
- `focus-window-or-workspace` exists in mango too (Mod+J/K preserved).
- Move/swap uses `exchange_client` (mango 0.16.3 has no plain
  `move_client`); consume/expel maps to `scroller_stack`.
- Monitor positions must be `x >= 0` (XWayland breaks with negative
  coordinates), so the left external output is at `x=0` and `eDP-1` at
  `x=1920` — same order as niri, shifted right.
- `sloppyfocus`/`warpcursor` are off: niri has `focus-follows-mouse` and
  `warp-mouse-to-focus` commented out.
- Helper scripts (`my-bookmark`, `my-commands`, `my-recorder`) are shared
  with niri via `~/.config/niri/`, not duplicated.

## Not ported (no mango 0.16.3 equivalent)

- `show-hotkey-overlay` (slot reused for `reload_config`)
- `niri msg pick-window | … | kill` (use `SUPER+SHIFT+x` = `killclient,force`)
- `move-workspace-{up,down}` / `move-{column,window}-to-monitor-*` beyond
  `tagmon` / `focus-column-{first,last}` (approximated with tag 1/9 jumps)
- `set-column-width`/`set-window-height` ±10% (use Mod+R presets,
  Mod+minus/equal `setmfact`)
- `toggle-window-floating` focus swap, tabbed columns, keyboard-shortcut
  inhibit toggle, OBS `pass`, touchpad scroll binds (commented out in niri
  anyway)
- Screenshot-a-window: `ALT+Print` does a region capture like `Print`
  (mango 0.16.3 has no capture-window dispatcher)
