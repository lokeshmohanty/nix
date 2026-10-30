{
  self,
  lib,
  config,
  ...
}:
{
  options.modules.editor.enable = lib.mkEnableOption "editor tooling";

  imports = [
    ./nvim.nix
    ./zk.nix
  ];
}
