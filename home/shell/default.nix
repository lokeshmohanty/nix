{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.modules.shell = {
    enable = lib.mkEnableOption "shell tooling";
    fish.enable = lib.mkEnableOption "fish shell";
    zsh.enable = lib.mkEnableOption "zsh shell";
    nushell.enable = lib.mkEnableOption "nushell";
  };

  config = lib.mkMerge [
    {
      modules.shell = {
        fish.enable = lib.mkDefault config.modules.shell.enable;
        zsh.enable = lib.mkDefault config.modules.shell.enable;
        nushell.enable = lib.mkDefault config.modules.shell.enable;
      };
    }
    (lib.mkIf (config.modules.shell.enable || config.modules.tui.enable) {
      home.packages = with pkgs; [
        exiftool
        jc
        jtbl
      ];
      home.shell.enableShellIntegration = true;
    })
  ];

  imports = [
    ./fish.nix
    ./zsh.nix
    ./nushell.nix
  ];
}
