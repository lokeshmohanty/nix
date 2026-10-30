{
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.modules.tui.direnv.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
