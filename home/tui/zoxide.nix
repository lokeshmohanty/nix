{
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.modules.tui.zoxide.enable {
    programs.zoxide.enable = true;
  };
}
