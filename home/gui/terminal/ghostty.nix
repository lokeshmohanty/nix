{
  config,
  lib,
  ...
}:
{
  options.modules.gui.ghostty.enable = lib.mkEnableOption "ghostty terminal";

  config = lib.mkIf config.modules.gui.ghostty.enable {
    programs.ghostty = {
      enable = true;
      installVimSyntax = true;
      settings = {
        gtk-single-instance = true;
      };
    };
  };
}
