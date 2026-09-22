{ pkgs, ... }:
{
  imports = [ ../../system ];

  hardware.bluetooth.enable = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  services.xserver.videoDrivers = [ "amdgpu" ];

  # boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 80;

  programs.nix-ld = {
    enable = true;
    libraries = [
      (pkgs.runCommand "steamrun-lib" { } "mkdir $out; ln -s ${pkgs.steam-run.fhsenv}/usr/lib64 $out/lib")
    ];
  };

  # NFS shares from airex-nas. The exports are restricted to 100.0.0.0/8 and
  # 10.24.36.0/24, so these are reachable over Tailscale — this host's LAN
  # address (192.168.1.0/24) is NOT in the ACL and will be refused.
  #
  # mount.nfs and rpcbind come from `boot.supportedFilesystems` in
  # system/default.nix; no `services.rpcbind.enable` is needed here (the
  # nfs module turns it on itself).
  #
  # Both are automounts: nothing is mounted until the path is touched, and each
  # unmounts after 60s idle. That keeps a NAS or Tailscale outage from blocking
  # boot. `soft` makes I/O fail with an error instead of hanging forever if the
  # link drops mid-operation; the NFS version is left unpinned so the kernel
  # negotiates down from 4.2 on its own.
  # Local SATA SSD (Samsung 860 EVO, LABEL=ssd). Automount like the NFS
  # shares above: nothing mounts until the path is touched, unmounts after
  # 60s idle, and `nofail` keeps a missing/damaged disk from blocking boot.
  fileSystems."/run/media/lokesh/ssd" = {
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

  fileSystems."/mnt/nas/research" = {
    device = "airex-nas:/volume1/research";
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
    device = "airex-nas:/volume1/datasets";
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

  networking.hostName = "sudarshan";
  gaming.enable = true;
  searxng.enable = true; # local DuckDuckGo backend for pi web_search
  desktop.niri.enable = true;
  desktop.hyprland.enable = false;

  powerManagement.enable = true;
  services.thermald.enable = true;
  # services.tlp.enable = true;
}
