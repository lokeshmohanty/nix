{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.modules.tui.yazi.enable {
    home.packages = [ pkgs.ripdrag ];
    programs.yazi = {
      enable = true;
      settings = {
        mgr = {
          show_hidden = false;
          sort_by = "mtime";
          sort_dir_first = true;
          sort_reverse = true;
        };
      };
      plugins = { drag = pkgs.yaziPlugins.drag; };
      keymap = {
        mgr.prepend_keymap = [
          {
            on = [ "<C-n>" ];
            run = "plugin drag";
            desc = "Drag and drop";
          }
        ];
      };
    };
  };
}
