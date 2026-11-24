{ config, pkgs, ... }: {
  imports = [ ../../system ];

  hardware.graphics.enable = true;
  hardware.nvidia-container-toolkit.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    # 595.112.07 oopsed in nvidia_uvm (process_lazy_free, HMM path) on
    # 2026-11-13 and hard-hung the box; moved off that branch.
    package = config.boot.kernelPackages.nvidiaPackages.latest;
  };
  # HMM is unused by plain CUDA/PyTorch and was in the crashing fault path.
  boot.extraModprobeConfig = "options nvidia_uvm uvm_disable_hmm=1";
  # Reboot on a kernel oops instead of freezing until a power-button reset.
  boot.kernel.sysctl."kernel.panic_on_oops" = 1;
  boot.kernel.sysctl."kernel.panic" = 10;
  services.xserver.videoDrivers = [ "nvidia" ];
  nixpkgs.config.nvidia.acceptLicense = true;
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
    settings.publish = {
      disable-publishing = false;
      disable-user-service-publishing = false;
      publish-addresses = true;
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

  fileSystems."/mnt/ssd" = {
    device = "/dev/disk/by-uuid/42d7f20a-42b0-4153-aa91-b05394443e8c";
    fsType = "ext4";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=60"
      "x-systemd.mount-timeout=10"
      "nofail"
      "rw"
      "relatime"
      "errors=remount-ro"
    ];
  };

  # = loginctl enable-linger lokesh: keep the user manager (and rootless
  # Podman) running after logout/reboot so /mnt/hdd2/Servers compose stacks
  # auto-start via podman-restart.service.
  users.users.lokesh.linger = true;

  networking.hostName = "bhaskara";
  searxng.enable = true; # local DuckDuckGo backend for pi web_search
}
