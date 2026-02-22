{
  config,
  pkgs,
  ...
}: {
  imports = [../../home/terminal/tmux.nix ../../home/editor];

  nixpkgs = {
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
      # enable scrolling in git diff
      DELTA_PAGER = "less -R";
      TERM = "xterm-256color";
    };
    packages = with pkgs; [
      # Misc
      tlrc # rust client for tldr
      fd # search for files by name, faster than find
      ripgrep

      yq-go # yaml processor https://github.com/mikefarah/yq
      just # a command runner like make, but simpler
      delta # A viewer for git and diff output
      lazygit # Git terminal UI.
      git-lfs
      hyperfine # command-line benchmarking tool
      gping # ping, but with a graph(TUI)
      doggo # DNS client for humans
      duf # Disk Usage/Free Utility - a better 'df' alternative
      gdu # disk usage analyzer(replacement of `du`)

      exiftool #  Read and write meta information in files
      nix-your-shell # use fish in nix develop / nix shell ...

      cascadia-code # font
      pyright # python language server
    ];
    shell.enableShellIntegration = true;
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "${config.home.homeDirectory}/.nix";
  };

  programs = {
    fzf = {
      enable = true;
      tmux.enableShellIntegration = true;
    };
    zoxide.enable = true;
    starship.enable = true;
    yazi = {
      enable = true;
      settings = {
        mgr = {
          show_hidden = false;
          sort_by = "mtime";
          sort_dir_first = true;
          sort_reverse = true;
        };
      };
    };
    # direnv = {
    #   enable = true;
    #   nix-direnv.enable = true;
    # };
  };
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting
      fish_vi_key_bindings

      if command -q nix-your-shell
        nix-your-shell fish | source
      end

      fish_add_path "/usr/local/cuda-13.0/bin"
      set -Ux LD_LIBRARY_PATH /usr/local/cuda-13.0/lib64
    '';
    shellAbbrs = {
      e = "nvim";
      d = "docker";
      g = "git";
      s = "sudo -E";
      p = "python";

      # docker
      di = "docker image";
      dc = "docker container";

      # tmux
      ta = "tmux -u attach -t";
      tn = "tmux -u new-session -t";
      tl = "tmux -u list-sessions";
      tk = "tmux -u kill-session -t";

      # nix
      nd = "nix develop";
      nl = "nix-locate";
      nr = "nix run nixpkgs#";
      ns = "nix search nixpkgs";
      nq = "nix-env -qaP";
      nsh = "nix-shell -p";
    };
    functions = {
      gitignore = "curl -sL https://www.gitignore.io/api/$argv";
      y = ''
        set tmp (mktemp -t "yazi-cwd.XXXXXX")
        yazi $argv --cwd-file="$tmp"
        if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
          builtin cd -- "$cwd"
        end
        rm -f -- "$tmp"
      '';
    };
    plugins = [
      {
        name = "bass";
        src = pkgs.fishPlugins.bass;
      }
      {
        name = "colored-man-output";
        src = pkgs.fishPlugins.colored-man-pages.src;
      }
      {
        name = "autopair";
        src = pkgs.fishPlugins.autopair.src;
      }
    ];
  };

  programs.git = {
    enable = true;
    settings.user.name = "Lokesh Mohanty";
    settings.user.email = "lokesh1197@gmail.com";
  };
  programs.gh.enable = true;
  programs.home-manager.enable = true;
  home.stateVersion = "25.05";
}
