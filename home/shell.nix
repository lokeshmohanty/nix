{pkgs, ...}: {
  home.packages = with pkgs; [
    exiftool #  Read and write meta information in files
    nix-your-shell # use fish in nix develop / nix shell ...
  ];
  home.shell.enableShellIntegration = true;
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
      plugins = let
        # nix-prefetch-github <owner> <repo>
        yazi-plugins = pkgs.fetchFromGitHub {
          owner = "yazi-rs";
          repo = "plugins";
          rev = "2bf70d880e02db95394de360668325b46f804791";
          hash = "sha256-0A5UVbrP9+GRvX14VQm4Yxw+P9Ca5gtlk9qkLCVf5+Q=";
        };
      in {
        # chmod = "${yazi-plugins}/chmod.yazi";
        # smart-enter = "${yazi-plugins}/smart-enter.yazi";
      };
      keymap = {
        mgr.prepend_keymap = [
          {
            on = ["<C-n>"];
            run = ''
              shell '${pkgs.ripdrag}/bin/ripdrag "$@" -x 2>/dev/null &' --confirm
            '';
            desc = "Drag and drop";
          }
          # {
          #   on = ["l"];
          #   run = "plugin smart-enter";
          #   desc = "Enter the child directory, or open the file";
          # }
        ];
      };
    };
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
  programs.nushell = {
    enable = true;
    configFile.text = ''
      $env.config = {
        edit_mode: vi
      }
    '';
  };
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting
      fish_vi_key_bindings

      if command -q nix-your-shell
        nix-your-shell fish | source
      end
    '';
    shellAbbrs = {
      e = "emacsclient -c -a 'nvim'";
      d = "docker";
      g = "git";
      s = "sudo -E";
      p = "python";
      x = "env -u WAYLAND_DISPLAY";

      # docker
      di = "docker image";
      dc = "docker container";
      de = "distrobox enter";

      # tmux
      t = "tmux";
      ta = "tmux attach -t";
      tn = "tmux new-session -t";
      tl = "tmux list-sessions";
      tk = "tmux kill-session -t";

      # nix
      nd = "nix develop";
      nl = "nix-locate";
      nr = "nix run nixpkgs#";
      ns = "nix search nixpkgs";
      nq = "nix-env -qaP";
      nsh = "nix-shell -p";

      # hypr = "dbus-run-session Hyprland";
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

      haskellEnv = ''
        for el in $argv
          set hpkgs $hpkgs "haskellPackages.ghcWithPackages.$el"
        end
        nix-shell --command fish -p $hpkgs
      '';

      pythonEnv = {
        description = "start a nix-shell with the given python packages";
        argumentNames = ["pythonVersion"];
        body = ''
          if set -q argv[2]
            # set pythonVersion $argv[1]
            set argv $argv[2..-1]
          end
          echo "Python Version: $pythonVersion"

          for el in $argv
            set ppkgs $ppkgs "python"$pythonVersion"Packages.$el"
          end

          nix-shell --command fish -p $ppkgs
        '';
      };
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
}
