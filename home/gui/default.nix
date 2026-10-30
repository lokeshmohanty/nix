{
  lib,
  config,
  ...
}:
{
  options.modules.gui.enable = lib.mkEnableOption "GUI toolkit integration";

  config = lib.mkMerge [
    {
      modules.gui = {
        browser.enable = lib.mkDefault config.modules.gui.enable;
        foot.enable = lib.mkDefault false;
        kitty.enable = lib.mkDefault config.modules.gui.enable;
        ghostty.enable = lib.mkDefault config.modules.gui.enable;
        rofi.enable = lib.mkDefault config.modules.gui.enable;
        satty.enable = lib.mkDefault config.modules.gui.enable;
        tofi.enable = lib.mkDefault config.modules.gui.enable;
      };
    }
    (lib.mkIf config.modules.gui.enable {
      qt.enable = true;
      qt.platformTheme.name = "gtk3";
    })
  ];

  imports = [
    ./browser
    ./launcher
    ./terminal
    ./pdf.nix
    ./xdg.nix
    ./satty.nix
  ];
}
