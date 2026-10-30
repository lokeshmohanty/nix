{
  pkgs,
  ...
}:
{
  imports = [ ../../system ./tailscale-second.nix ];

  hardware.graphics.enable = true;

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

  desktop.niri.enable = true;

  sshServer.enable = true;
  programs.virt-manager.enable = true;

  networking.hostName = "bose";
  searxng.enable = true; # local DuckDuckGo backend for pi web_search
}
