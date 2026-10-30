{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.modules.tui = {
    enable = lib.mkEnableOption "terminal UI tooling";
    fzf.enable = lib.mkEnableOption "fzf";
    yazi.enable = lib.mkEnableOption "yazi";
    direnv.enable = lib.mkEnableOption "direnv integration";
    zoxide.enable = lib.mkEnableOption "zoxide integration";
  };

  config = {
    modules.tui = {
      fzf.enable = lib.mkDefault config.modules.tui.enable;
      yazi.enable = lib.mkDefault config.modules.tui.enable;
      direnv.enable = lib.mkDefault config.modules.tui.enable;
      zoxide.enable = lib.mkDefault config.modules.tui.enable;
      tmux.enable = lib.mkDefault config.modules.tui.enable;
    };
  };

  imports = [
    ./fzf.nix
    ./yazi.nix
    ./direnv.nix
    ./zoxide.nix
    ./tmux.nix
  ];
}
