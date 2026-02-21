{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    ./terminal
    ./browser
    ./editor.nix
    ./launcher.nix
    ./shell.nix
    ./xdg.nix
    ./stylix.nix
  ];

  nixpkgs = {
    overlays = [
      inputs.nix-alien.overlays.default
    ];
    config = {
      allowUnfree = true;
    };
  };

  home = {
    username = "lokesh";
    homeDirectory = "/home/lokesh";
    sessionPath = ["$HOME/.local/bin"];
    sessionVariables = {
      LESSHISTFILE = config.xdg.cacheHome + "/less/history";
      LESSKEY = config.xdg.configHome + "/less/lesskey";
      WINEPREFIX = config.xdg.dataHome + "/wine";

      # set default applications
      BROWSER = "firefox";

      # enable scrolling in git diff
      DELTA_PAGER = "less -R";

      TERM = "xterm-256color";
    };
    packages = with pkgs; [
      # Misc
      tlrc # rust client for tldr
      # cowsay
      gnupg
      gnumake

      # tui applications
      # lazygit lazysql lazydocker

      imagemagick
      # pandoc
      pass
      rclone
      yt-dlp
      ffmpeg


      # isync   # sync emails
      # maim    # screenshots
      # nixfmt  # nix formatter
      # nim
      sqlite
      # isort

      fzf
      fd # search for files by name, faster than find
      ripgrep

      yq-go # yaml processor https://github.com/mikefarah/yq
      just # a command runner like make, but simpler
      delta # A viewer for git and diff output
      hyperfine # command-line benchmarking tool
      gping # ping, but with a graph(TUI)
      doggo # DNS client for humans
      duf # Disk Usage/Free Utility - a better 'df' alternative
      gdu # disk usage analyzer(replacement of `du`)

      # nix related
      nix-alien # run unpatched binaries

      # it provides the command `nom` works just like `nix
      # with more details log output
      nix-output-monitor
      # nix-index # A small utility to index nix store paths
      nix-init # generate nix derivation from url
      # https://github.com/nix-community/nix-melt
      # https://github.com/utdemir/nix-tree
      nix-tree # A TUI to visualize the dependency graph of a nix derivation

      # productivity
      # croc # File transfer between computers securely and easily

      # other
      # remmina
      # freerdp # remote desktop client
    ];
  activation.hyprland = lib.mkAfter ''
    ln -sf ${builtins.toPath ../config/hypr} ${config.xdg.configHome}
    ln -sf ${builtins.toPath ../config/waybar} ${config.xdg.configHome}
    ln -sf ${builtins.toPath ../config/wlogout} ${config.xdg.configHome}
    ln -sf ${builtins.toPath ../config/swappy} ${config.xdg.configHome}
    ln -sf ${builtins.toPath ../config/gtk.css} ${config.xdg.configHome}
    ln -sf ${builtins.toPath ../config/icons} ${config.xdg.configHome}
  '';
  };

  stylixConfig.enable = true;
  stylixConfig.theme = "everforest-dark-hard"; #"terracotta";
  wallpaper = ./../wallpapers/0016.jpg;

  # Hyprland
  home.sessionVariables.NIXOS_OZONE_WL = "1";

  ## Documentation: https://github.com/viperML/nh
  ## Video: https://www.youtube.com/watch?v=DnA4xNTrrqY
  ## Nix Helper
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "${config.home.homeDirectory}/.nix";
  };

  programs.zathura = {
    enable = true;
    extraConfig = ''
      set synctex true
      set synctex-editor-command "nvim --headless -c \"VimtexInverseSearch %{line} '%{input}'\""
    '';
  };
  # programs.obs-studio = {
  #   enable = true;
  #   # plugins = with pkgs.obs-studio-plugins; [
  #   #   obs-backgroundremoval
  #   #   obs-move-transition
  #   #   advanced-scene-switcher
  #   # ];
  # };
  programs.firefox.enable = true;
  # programs.keychain = { enable = true; keys = [ "id_ed25519" ]; };
  programs.gh = {
    enable = true;
    extensions = [pkgs.gh-dash];
  };
  programs.nix-index.enable = true;

  services.gammastep = {
    enable = true;
    temperature = {
      day = 5000;
      night = 2500;
    };
    latitude = 13.0;
    longitude = 77.5;
  };

  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
  };

  # Enable home-manager and git
  programs.home-manager.enable = true;
  programs.git.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "25.05";
}
