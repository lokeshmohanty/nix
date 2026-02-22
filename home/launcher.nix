{
  pkgs,
  config,
  lib,
  ...
}: {
  home.packages = [pkgs.rofi];
  home.activation.rofi = lib.mkAfter ''
    ln -sf "../config/rofi" ${config.xdg.configHome}
  '';
}
