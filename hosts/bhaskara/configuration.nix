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

  # NFS shares from airex-nas. Reachable by LAN IP (10.24.36.0/24 is in the
  # export ACL); the Tailscale name `airex-nas` is unreliable here because the
  # NAS's tailscaled can be down even when the box and NFS are up.
  # Automounts: nothing mounts until touched, each unmounts after 60s idle, and
  # `soft` makes I/O fail instead of hanging if the link drops mid-operation.
  fileSystems."/mnt/nas/research" = {
    device = "10.24.36.19:/volume1/research";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=60"
      "x-systemd.mount-timeout=10"
      "_netdev"
      "rw"
      "soft"
    ];
  };

  fileSystems."/mnt/nas/datasets" = {
    device = "10.24.36.19:/volume1/datasets";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=60"
      "x-systemd.mount-timeout=10"
      "_netdev"
      "rw"
      "soft"
    ];
  };

  networking.hostName = "bhaskara";
  searxng.enable = true; # local DuckDuckGo backend for pi web_search
}
