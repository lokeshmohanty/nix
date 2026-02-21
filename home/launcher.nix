{ pkgs, config, lib, ... }: {
  home.packages = [pkgs.rofi];
  home.activation.rofi = lib.mkAfter ''
    ln -sf ${builtins.toPath ../config/rofi} ${config.xdg.configHome}
  '';
}
