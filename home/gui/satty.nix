# Reference: https://github.com/Satty-org/Satty
{ config, lib, ... }:
{
  options.modules.gui.satty.enable = lib.mkEnableOption "satty screenshot editor";

  config = lib.mkIf config.modules.gui.satty.enable {
    programs.satty = {
      enable = true;
      settings = {
        general = {
          corner-roundness = 12;
          initial-tool = "brush";
          output-filename = "~/Pictures/Screenshots/%Y-%m-%d_%H:%M:%S.png";
        };
        font.family = config.vars.fontName;
      };
    };
  };
}
