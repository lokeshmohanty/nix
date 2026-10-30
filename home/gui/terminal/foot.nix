{ lib, config, ... }:
{
  options.modules.gui.foot.enable = lib.mkEnableOption "foot terminal";

  config = lib.mkIf config.modules.gui.foot.enable {
    programs.foot = {
      enable = true;
      settings = {
        main = {
          term = "xterm-256color";
          pad = "3x3";
        };
      };
    };
  };
}
