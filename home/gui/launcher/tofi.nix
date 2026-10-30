{ config, lib, ... }:
{
  options.modules.gui.tofi.enable = lib.mkEnableOption "tofi launcher";

  config = lib.mkIf config.modules.gui.tofi.enable {
    programs.tofi = {
      enable = true;
      settings = {
        font = config.vars.fontName;
        font-size = "16";
        width = "100%";
        height = "100%";
        border-width = 0;
        outline-width = 0;
        background-color = "#000A";
        hide-cursor = true;
      };
    };
  };
}
