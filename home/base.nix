{
  inputs,
  config,
  pkgs,
  self,
  ...
}:
{
  nix.registry.nixpkgs.flake = inputs.nixpkgs;

  nixpkgs = {
    overlays = [
      inputs.nix-alien.overlays.default
    ];
    config = {
      allowUnfree = true;
    };
  };

  home = {
    username = config.vars.username;
    homeDirectory = config.vars.homeDirectory;
    sessionPath = [
      "$HOME/.local/bin"
      "$HOME/.cargo/bin"
    ];
    sessionVariables = {
      LESSHISTFILE = config.xdg.cacheHome + "/less/history";
      LESSKEY = config.xdg.configHome + "/less/lesskey";
      WINEPREFIX = config.xdg.dataHome + "/wine";
      # enable scrolling in git diff
      DELTA_PAGER = "less -R";
      TERM = "xterm-256color";
      NIXCONFIG = config.vars.nixDir;
      NIXPKGS_ALLOW_UNFREE = 1;
    };
    packages = with pkgs; [
      self.packages.${pkgs.stdenv.hostPlatform.system}.ghost-build
      self.packages.${pkgs.stdenv.hostPlatform.system}.ab-download-manager
      postgresql

      # Misc
      tlrc # rust client for tldr
      # cowsay
      gnupg
      gnumake

      # tui applications
      lazygit
      lazysql
      lazydocker

      pandoc
      pass
      rclone
      yt-dlp
      ffmpeg

      # Chrome-fingerprinted curl. Cloudflare-protected hosts reject Node's and
      # stock curl's TLS handshake even with a valid clearance cookie; abdm-grab
      # uses this to resolve them (see docs/how-to/abdm-grab.md).
      curl-impersonate

      sqlite

      fzf
      fd # fd alternative
      sd # sed alternative
      ripgrep # grep alternative

      yq-go # yaml processor https://github.com/mikefarah/yq
      just # a command runner like make, but simpler
      delta # A viewer for git and diff output
      hyperfine # command-line benchmarking tool
      gping # ping, but with a graph(TUI)
      doggo # DNS client for humans
      duf # Disk Usage/Free Utility - a better 'df' alternative
      gdu # disk usage analyzer(replacement of `du`)
      qrcp # for generating qr code for file transfer

      # nix related
      nix-alien # run unpatched binaries

      # it provides the command `nom` works just like `nix
      # with more details log output
      nix-output-monitor
      nix-index # A small utility to index nix store paths

      # productivity
      # croc # File transfer between computers securely and easily

      # other
      # remmina
      # freerdp # remote desktop client
    ];
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "26.05";
}
