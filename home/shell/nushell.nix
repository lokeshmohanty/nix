{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.modules.shell.nushell.enable {
    programs.nushell = {
      enable = true;
      configFile.text = ''
        $env.config = {
          edit_mode: vi
        }
      '';
    };
  };
}
