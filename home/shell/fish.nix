{
  pkgs,
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.modules.shell.fish.enable {
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
  };
}
