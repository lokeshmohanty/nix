{ lib, config, ... }:
{
  options.modules.activations.enable = lib.mkEnableOption "desktop activation symlinks";

  config = lib.mkIf config.modules.activations.enable {
    home.activation = {
      # XDG data/state home. Guarantee ~/.local exists owned by the primary
      # group: the NixOS syncthing service (User=lokesh Group=syncthing) creates
      # missing parents on first start and would otherwise leave ~/.local as
      # lokesh:syncthing. That unmapped group + no o+x breaks rootless podman
      # userns_mode="keep-id" (crun: open .../merged: Permission denied).
      local-dir = lib.mkAfter ''
        mkdir -p ${config.home.homeDirectory}/.local
        chgrp "$(id -gn)" ${config.home.homeDirectory}/.local
        chmod 700 ${config.home.homeDirectory}/.local
      '';
      hyprland = lib.mkIf config.modules.gui.enable (
        lib.mkAfter ''
          ln -sfn ${config.vars.nixDir}/config/hypr ${config.xdg.configHome}
          ln -sfn ${config.vars.nixDir}/config/waybar ${config.xdg.configHome}
          ln -sfn ${config.vars.nixDir}/config/wlogout ${config.xdg.configHome}
          ln -sfn ${config.vars.nixDir}/config/swappy ${config.xdg.configHome}
          ln -sfn ${config.vars.nixDir}/config/gtk.css ${config.xdg.configHome}
          ln -sfn ${config.vars.nixDir}/config/icons ${config.xdg.configHome}
        ''
      );
      niri = lib.mkIf config.modules.gui.enable (
        lib.mkAfter ''
          ln -sfn ${config.vars.nixDir}/config/niri ${config.xdg.configHome}
        ''
      );
      noctalia = lib.mkIf config.modules.gui.enable (
        lib.mkAfter ''
          ln -sfn ${config.vars.nixDir}/config/noctalia ${config.xdg.configHome}
        ''
      );
      scripts = lib.mkIf config.modules.shell.enable (
        lib.mkAfter ''
          mkdir -p ${config.home.homeDirectory}/.local/bin
          ln -sfn ${config.vars.nixDir}/scripts/* ${config.home.homeDirectory}/.local/bin/
        ''
      );
      inkscape = lib.mkIf config.modules.gui.enable (
        lib.mkAfter ''
          ln -sfn ${config.vars.nixDir}/config/inkscape ${config.xdg.configHome}/inkscape
        ''
      );
      # Agentic harness (see config/agentic-harness/agents/docs/layout.md).
      # ~/.agents is a whole-dir symlink; ~/.claude and ~/.pi stay REAL dirs
      # (runtime state, credentials) with selective links inside.
      # ln -sfn, never ln -sf: -sf on an existing dir drops the link INSIDE it.
      agents = lib.mkIf config.modules.ai.enable (
        lib.mkAfter ''
          ln -sfn ${config.vars.nixDir}/config/agentic-harness/agents ${config.home.homeDirectory}/.agents
        ''
      );
      claude = lib.mkIf config.modules.ai.enable (
        lib.mkAfter ''
          ln -sfn ${config.vars.nixDir}/config/agentic-harness/claude ${config.home.homeDirectory}/.claude
        ''
      );
      pi = lib.mkIf config.modules.ai.enable (
        lib.mkAfter ''
          ln -sfn ${config.vars.nixDir}/config/agentic-harness/pi ${config.home.homeDirectory}/.pi
        ''
      );
      # pi-web-access reads web-search.json from $XDG_CONFIG_HOME/pi (set by
      # home-manager xdg.configHome), NOT from ~/.pi. Without this link the
      # repo-tracked file above is shadowed by an unmanaged ~/.config/pi file.
      # Symlink it so the repo file is the single source of truth.
      pi-web-search = lib.mkIf config.modules.ai.enable (
        lib.mkAfter ''
          mkdir -p ${config.xdg.configHome}/pi
          ln -sfn ${config.vars.nixDir}/config/agentic-harness/pi/web-search.json ${config.xdg.configHome}/pi/web-search.json
        ''
      );
      codex = lib.mkIf config.modules.ai.enable (
        lib.mkAfter ''
          ln -sfn ${config.vars.nixDir}/config/agentic-harness/codex ${config.home.homeDirectory}/.codex
        ''
      );
      gemini = lib.mkIf config.modules.ai.enable (
        lib.mkAfter ''
          ln -sfn ${config.vars.nixDir}/config/agentic-harness/gemini ${config.home.homeDirectory}/.gemini
        ''
      );
      harness-bin = lib.mkIf config.modules.ai.enable (
        lib.mkAfter ''
          mkdir -p ${config.home.homeDirectory}/.local/bin
          ln -sfn ${config.vars.nixDir}/config/agentic-harness/bin/* ${config.home.homeDirectory}/.local/bin/
        ''
      );
    };
  };
}
