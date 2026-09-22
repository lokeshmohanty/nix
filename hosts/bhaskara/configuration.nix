{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [ ../../system ];

  hardware.graphics.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
  };
  services.xserver.videoDrivers = [ "nvidia" ];
  nixpkgs.config = {
    nvidia.acceptLicense = true;
  };
  gaming.enable = false;
  desktop.niri.enable = true;

  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 80;

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      expat
      libz
      coreutils
      binutils
      libgcc
    ];
    # libraries = [(pkgs.runCommand "steamrun-lib" {} "mkdir $out; ln -s ${pkgs.steam-run.fhsenv}/usr/lib64 $out/lib")];
  };

  # services.cloudflare-warp = {
  #   enable = true;
  #   openFirewall = true;
  # };
  # services.cloudflared.enable = true;

  # Printing
  # https://nixos.wiki/wiki/Printing
  # Access CUPS interface at http://localhost:631
  services.printing = {
    enable = true;
    # NIXPKGS_ALLOW_UNFREE=1 nix-shell -p hplipWithPlugin --run 'sudo -E hp-setup'
    drivers = with pkgs; [ hplipWithPlugin ];
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
  searxng.enable = true; # local DuckDuckGo backend for pi web_search
}
