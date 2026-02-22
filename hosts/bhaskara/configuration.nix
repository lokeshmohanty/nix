{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [../../system];

  hardware.graphics.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
  };
  nixpkgs.config.nvidia.acceptLicense = true;
  gaming.enable = false;

  programs.nix-ld = {
    enable = true;
    # libraries = [(pkgs.runCommand "steamrun-lib" {} "mkdir $out; ln -s ${pkgs.steam-run.fhsenv}/usr/lib64 $out/lib")];
  };

  services.cloudflare-warp = {
    enable = true;
    openFirewall = true;
  };
  # services.cloudflared.enable = true;

  # Printing
  # https://nixos.wiki/wiki/Printing
  # Access CUPS interface at http://localhost:631
  services.printing = {
    enable = true;
    # NIXPKGS_ALLOW_UNFREE=1 nix-shell -p hplipWithPlugin --run 'sudo -E hp-setup'
    drivers = with pkgs; [hplipWithPlugin];
  };
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      userServices = true;
      addresses = true;
    };
  };

  sshServer.enable = true;
  programs.virt-manager.enable = true;

  networking.hostName = "bhaskara";
}
