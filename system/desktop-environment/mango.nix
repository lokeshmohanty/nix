{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ inputs.mangowm.nixosModules.mango ];
  options.desktop.mango = {
    enable = lib.mkEnableOption "Mango: Scrolling/Tiling based window manager";
  };
  config = lib.mkIf config.desktop.mango.enable {
    environment.sessionVariables.GDK_BACKEND = "wayland";
    environment.systemPackages = with pkgs; [
      xdg-desktop-portal-gnome
      xwayland-satellite
      cage # wayland kiosk
      libsecret
      tofi # configured in home-manager
      wtype
    ];
    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
    xdg.portal.config.common.default = "gnome";

    programs.mango.enable = true;

    security.soteria.enable = true;
  };
}
