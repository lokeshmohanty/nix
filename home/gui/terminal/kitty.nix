{
  config,
  lib,
  ...
}:
{
  options.modules.gui.kitty.enable = lib.mkEnableOption "kitty terminal";

  config = lib.mkIf config.modules.gui.kitty.enable {
    programs.kitty = {
      enable = true;
      enableGitIntegration = true;
      actionAliases = {
        "launch_tab" = "launch --cwd=current --type=tab";
        "launch_window" = "launch --cwd=current --type=os-window";
      };
      settings = {
        allow_remote_control = "yes";
        listen_on = "unix:/tmp/mykitty";
        forward_remote_control = "yes";
        confirm_os_window_close = "2";
        shell = "fish";
      };
      # Foot emits CSI 13;2u (CSI-u) for Shift+Enter by default; kitty's
      # legacy mode sends a plain CR, so tmux (extended-keys-format csi-u)
      # can't tell it apart from Enter. Emit the same sequence foot did so
      # tmux/inner apps see a distinct Shift+Enter again.
      keybindings = {
        "shift+enter" = "send_text all \\x1b[13;2u";
      };
      shellIntegration.enableFishIntegration = true;
    };
  };
}
