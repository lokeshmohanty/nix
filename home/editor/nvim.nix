{
  self,
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.modules.editor.enable {
    home.packages = [
      self.packages.${pkgs.stdenv.hostPlatform.system}.nvim
    ];
    home.sessionVariables.EDITOR = "vi";
    home.activation.nvim = lib.mkAfter ''
      ln -sf ${config.vars.nixDir}/pkgs/nvim ${config.xdg.configHome}
    '';
  };
}
