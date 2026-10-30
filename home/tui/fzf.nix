{
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.modules.tui.fzf.enable {
    programs.fzf = {
      enable = true;
      tmux.enableShellIntegration = true;
    };
  };
}
