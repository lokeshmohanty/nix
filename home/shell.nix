{
  pkgs,
  lib,
  config,
  ...
}:
let
  shellCfg = config.modules.shell;
  tuiCfg = config.modules.tui;
in
{
  options.modules = {
    shell = {
      enable = lib.mkEnableOption "shell tooling";
      fish.enable = lib.mkEnableOption "fish shell";
      zsh.enable = lib.mkEnableOption "zsh shell";
      nushell.enable = lib.mkEnableOption "nushell";
    };
    tui = {
      enable = lib.mkEnableOption "terminal UI tooling";
      fzf.enable = lib.mkEnableOption "fzf";
      yazi.enable = lib.mkEnableOption "yazi";
      direnv.enable = lib.mkEnableOption "direnv integration";
      zoxide.enable = lib.mkEnableOption "zoxide integration";
    };
  };

  config = lib.mkMerge [
    {
      modules = {
        shell = {
          fish.enable = lib.mkDefault shellCfg.enable;
          zsh.enable = lib.mkDefault shellCfg.enable;
          nushell.enable = lib.mkDefault shellCfg.enable;
        };
        tui = {
          fzf.enable = lib.mkDefault tuiCfg.enable;
          yazi.enable = lib.mkDefault tuiCfg.enable;
          direnv.enable = lib.mkDefault tuiCfg.enable;
          zoxide.enable = lib.mkDefault tuiCfg.enable;
          tmux.enable = lib.mkDefault tuiCfg.enable;
        };
      };
    }
    (lib.mkIf (shellCfg.enable || tuiCfg.enable) {
      home.packages = with pkgs; [
        exiftool
        jc
        jtbl
      ];
      home.shell.enableShellIntegration = true;
    })
    (lib.mkIf tuiCfg.fzf.enable {
      programs.fzf = {
        enable = true;
        tmux.enableShellIntegration = true;
      };
    })
    (lib.mkIf tuiCfg.yazi.enable {
      home.packages = [ pkgs.ripdrag ];
      programs.yazi = {
        enable = true;
        settings = {
          mgr = {
            show_hidden = false;
            sort_by = "mtime";
            sort_dir_first = true;
            sort_reverse = true;
          };
        };
        plugins = { drag = pkgs.yaziPlugins.drag; };
        keymap = {
          mgr.prepend_keymap = [
            {
              on = [ "<C-n>" ];
              run = "plugin drag";
              desc = "Drag and drop";
            }
          ];
        };
      };
    })
    (lib.mkIf tuiCfg.zoxide.enable {
      programs.zoxide.enable = true;
    })
    (lib.mkIf tuiCfg.direnv.enable {
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
    })
    (lib.mkIf shellCfg.zsh.enable {
      programs.zsh = {
        enable = true;
        enableVteIntegration = true;
        autosuggestion.enable = true;
        defaultKeymap = "viins";
        zsh-abbr.enable = true;
        zsh-abbr.abbreviations = {
          d = "docker";
        };
        zsh-abbr.globalAbbreviations = {
          G = "| rg";
          L = "| less -R";
        };
      };
    })
    (lib.mkIf shellCfg.fish.enable {
      home.packages = [ pkgs.nix-your-shell ];
      programs.fish = {
        enable = true;
        interactiveShellInit = ''
          set fish_greeting
          fish_vi_key_bindings

          nix-your-shell fish | source
        '';
        shellAbbrs = {
          e = "emacsclient -c -a 'nvim'";
          d = "docker";
          g = "git";
          s = "sudo -E";
          p = "python";
          x = "env -u WAYLAND_DISPLAY";
          di = "docker image";
          dc = "docker container";
          de = "distrobox enter";
          t = "tmux";
          ta = "tmux attach -t";
          tn = "tmux new-session -t";
          tl = "tmux list-sessions";
          tk = "tmux kill-session -t";
          k = "kubectl";
          kg = "kubectl get";
          kl = "kubectl logs";
          ke = "kubectl exec -it";
          kgp = "kubectl get pods";
          nd = "nix develop";
          nl = "nix-locate";
          nr = "nix run nixpkgs#";
          ns = "nix search nixpkgs";
          nq = "nix-env -qaP";
          nsh = "nix-shell -p";
        };
        functions = {
          gitignore = "curl -sL https://www.gitignore.io/api/$argv";
          tab = "jc -l $argv | jtbl";
        };
        preferAbbrs = true;
        plugins = [
          {
            name = "bass";
            src = pkgs.fetchFromGitHub {
              owner = "edc";
              repo = "bass";
              rev = "79b62958ecf4e87334f24d6743e5766475bcf4d0";
              sha256 = "3d/qL+hovNA4VMWZ0n1L+dSM1lcz7P5CQJyy+/8exTc=";
            };
          }
          {
            name = "tide";
            src = pkgs.fishPlugins.tide.src;
          }
          {
            name = "autopair";
            src = pkgs.fishPlugins.autopair.src;
          }
        ];
      };
    })
    (lib.mkIf shellCfg.nushell.enable {
      programs.nushell = {
        enable = true;
        configFile.text = ''
          $env.config = {
            edit_mode: vi
          }
        '';
      };
    })
  ];
}
