{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.modules.shell.zsh.enable {
    programs.zsh = {
      enable = true;
      enableVteIntegration = true;
      autosuggestion.enable = true;
      defaultKeymap = "viins";
      zsh-abbr.enable = true;
      zsh-abbr.abbreviations = {
        d = "docker";
      };
      zsh-abbr.globalAbbreviations = {
        G = "| rg";
        L = "| less -R";
      };
    };
  };
}
