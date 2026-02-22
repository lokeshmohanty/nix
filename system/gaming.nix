{
  pkgs,
  lib,
  config,
  ...
}: {
  options.gaming.enable = lib.mkEnableOption "enable gaming";
  config = lib.mkIf config.gaming.enable {
    programs.steam = {
      enable = true;
      # remotePlay.openFirewall = true;
      # dedicatedServer.openFirewall = true;
      gamescopeSession.enable = true;
      extraCompatPackages = [pkgs.proton-ge-bin];
    };
    programs.gamemode.enable = true;
    hardware.steam-hardware.enable = true;
    environment.systemPackages = with pkgs; [
      mangohud
      lutris
      heroic
    ];
  };
}
