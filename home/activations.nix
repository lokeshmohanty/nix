{ lib, config, ... }:
let
  # Generate `ln -sfn` commands from an attrset of { targetPath: sourcePath }.
  # Each entry becomes: ln -sfn <sourcePath> <targetPath>
  mkLinks = links: lib.concatStringsSep "\n" (
    lib.mapAttrsToList (target: source: "ln -sfn ${source} ${target}") links
  );

  cfg = "${config.vars.nixDir}/config";
in
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

      gui-config = lib.mkIf config.modules.gui.enable (
        lib.mkAfter ''
          ${mkLinks {
            "${config.xdg.configHome}/hypr" = "${cfg}/hypr";
            "${config.xdg.configHome}/waybar" = "${cfg}/waybar";
            "${config.xdg.configHome}/wlogout" = "${cfg}/wlogout";
            "${config.xdg.configHome}/swappy" = "${cfg}/swappy";
            "${config.xdg.configHome}/gtk.css" = "${cfg}/gtk.css";
            "${config.xdg.configHome}/icons" = "${cfg}/icons";
            "${config.xdg.configHome}/niri" = "${cfg}/niri";
            "${config.xdg.configHome}/mango" = "${cfg}/mango";
            "${config.xdg.configHome}/noctalia" = "${cfg}/noctalia";
            "${config.xdg.configHome}/inkscape" = "${cfg}/inkscape";
          }}
        ''
      );

      scripts = lib.mkIf config.modules.shell.enable (
        lib.mkAfter ''
          mkdir -p ${config.home.homeDirectory}/.local/bin
          ln -sfn ${config.vars.nixDir}/scripts/* ${config.home.homeDirectory}/.local/bin/
        ''
      );

      ai-links = lib.mkIf config.modules.ai.enable (
        lib.mkAfter ''
          ${mkLinks {
            "${config.home.homeDirectory}/.agents" = "${cfg}/agentic-harness/agents";
            "${config.home.homeDirectory}/.claude" = "${cfg}/agentic-harness/claude";
            "${config.home.homeDirectory}/.pi" = "${cfg}/agentic-harness/pi";
            "${config.xdg.configHome}/pi/web-search.json" = "${cfg}/agentic-harness/pi/web-search.json";
            "${config.home.homeDirectory}/.codex" = "${cfg}/agentic-harness/codex";
            "${config.home.homeDirectory}/.gemini" = "${cfg}/agentic-harness/gemini";
          }}
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
