{
  pkgs,
  config,
  lib,
  ...
}:
{
  options.modules.gui.rofi.enable = lib.mkEnableOption "rofi launcher";

  config = lib.mkIf config.modules.gui.rofi.enable {
    home.packages = [ pkgs.rofi ];
    home.activation.rofi = lib.mkAfter ''
      ln -sf "${config.vars.nixDir}/config/rofi" ${config.xdg.configHome}
    '';
  };
}
