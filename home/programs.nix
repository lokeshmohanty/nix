{ config, pkgs, ...}: {
  ## Nix Helper
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "${config.vars.nixDir}";
  };
  # programs.keychain = { enable = true; keys = [ "id_ed25519" ]; };
  programs.gh = {
    enable = true;
    extensions = [ pkgs.gh-dash ];
  };
  programs.nix-index.enable = true;
  programs.go.enable = true;

  # services.mako = {
  #   enable = true;
  #   settings = {
  #     default-timeout = 5000; # in milliseconds
  #   };
  # };

  programs.home-manager.enable = true;
}
