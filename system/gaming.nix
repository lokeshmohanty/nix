{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.gaming.enable = lib.mkEnableOption "enable gaming";
  config = lib.mkIf config.gaming.enable {
    programs.steam = {
      enable = true;
      # remotePlay.openFirewall = true;
      # dedicatedServer.openFirewall = true;
      gamescopeSession.enable = true;
      extraCompatPackages = [ pkgs.proton-ge-bin ];
    };
    programs.gamemode.enable = true;
    hardware.steam-hardware.enable = true;
    # buildEnv only links directories listed in pathsToLink; the default
    # (set in system/default.nix) only covers /share/bash-completion and
    # /share/zsh, so we must explicitly add our lib directory.
    environment.pathsToLink = [ "/share/lib32-multimedia" ];

    nixpkgs.overlays = [
      (final: prev: {
        pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
          (python-final: python-prev: {
            steamworkspy = python-prev.steamworkspy.overrideAttrs (_: {
              dontCheckPythonMetadata = true;
            });
          })
        ];
      })
    ];

    environment.systemPackages = with pkgs; [
      mangohud
      (bottles.override { removeWarningPopup = true; })
      # 32-bit multimedia libraries for Wine/Bottles gstreamer plugins.
      # The wine-ge-proton runner bundles 32-bit gstreamer plugins (libgstlibav,
      # libgstasf, libgstogg, etc.) that depend on system 32-bit libs not present
      # in the Bottles FHS env or nix-ld. Placed in a separate directory to avoid
      # 32/64-bit SONAME collisions in nix-ld's flat /lib. To use them, set
      # LD_LIBRARY_PATH=/run/current-system/sw/share/lib32-multimedia/lib in
      # each bottle's Environment_Variables in bottle.yml.
      # NOTE: Use .out explicitly — libsndfile, lcms2, libxml2, and flac default
      # to their bin output, which lacks the lib/ directory.
      # SONAME mismatches (can't be fixed with current nixpkgs): libtheora
      # provides .so.2 (runner needs .so.1), libwebp provides .so.7 (runner
      # needs .so.6), libxml2 provides .so.16 (runner needs .so.2), flac
      # provides libFLAC.so.14 (runner needs .so.8). These affect non-essential
      # codecs (Theora video, WebP images, streaming, FLAC audio) only.
      (runCommand "multimedia-libs-i686" { }
        ''
          mkdir -p $out/share/lib32-multimedia/lib
          for pkg in ${pkgsi686Linux.libvdpau.out} ${pkgsi686Linux.libogg.out} ${pkgsi686Linux.libopus.out} ${pkgsi686Linux.libvorbis.out} ${pkgsi686Linux.libsndfile.out} ${pkgsi686Linux.speex.out} ${pkgsi686Linux.libtheora.out} ${pkgsi686Linux.libwebp.out} ${pkgsi686Linux.lcms2.out} ${pkgsi686Linux.libxml2.out} ${pkgsi686Linux.flac.out}; do
            if [ -d "$pkg/lib" ]; then
              for f in $pkg/lib/*.so*; do
                ln -sf "$f" "$out/share/lib32-multimedia/lib/$(basename "$f")"
              done
            fi
          done
        '')
    ];
  };
}
