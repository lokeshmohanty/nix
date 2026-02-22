# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # You can import other NixOS modules here
  imports = [
    # If you want to use modules from other flakes (such as nixos-hardware):
    # inputs.hardware.nixosModules.common-cpu-amd
    # inputs.hardware.nixosModules.common-ssd

    # You can also split up your configuration and import pieces of it here:
    ./security.nix
    ./gaming.nix
    ./services.nix
    ./programs.nix
    ./desktop-environment.nix
    ./fonts.nix
    ./ssh.nix
  ];

  nixpkgs = {
    overlays = [
      # If you want to use overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      allowUnfree = true;
      allowInsecure = false;
    };
  };

  nix = {
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    registry = lib.mapAttrs (_: value: {flake = value;}) inputs;

    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    settings = {
      experimental-features = "nix-command flakes";
      auto-optimise-store = true;
      trusted-users = ["lokesh"];

      # cachix
      substituters = [
        "https://hyprland.cachix.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
      extra-substituters = ["https://yazi.cachix.org"];
      extra-trusted-public-keys = ["yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="];
    };
    # Garbage collection is being handled by "nix-helper (nh)"
    # gc = {
    #   automatic = true;
    #   dates = "weekly";
    #   options = "--delete-older-than 7d";
    # };
  };

  networking.networkmanager.enable = true;
  networking.firewall.enable = false;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = ["ntfs"];

  time.timeZone = "Asia/Kolkata";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  users.users = {
    lokesh = {
      # If you do, you can skip setting a root password by
      # passing '--no-root-passwd' to nixos-install.
      # Be sure to change it (using passwd) after rebooting!
      shell = pkgs.fish;
      initialPassword = "nixos";
      isNormalUser = true;
      description = "Lokesh Mohanty";
      extraGroups = ["wheel" "input" "audio" "video" "networkmanager" "libvirtd"];
    };
  };
  users.defaultUserShell = pkgs.fish;
  environment.binsh = "${pkgs.dash}/bin/dash";

  environment.systemPackages = with pkgs; [
    # gui applications
    google-chrome
    onlyoffice-desktopeditors
    motrix
    zotero
    (inkscape-with-extensions.override {inkscapeExtensions = [inkscape-extensions.textext];})
    # krita
    vscode-fhs

    # cli applications
    # tesseract
    aria2
    gh

    # system utilities
    inxi
    neofetch
    bat
    duf
    libtool
    zip
    unzip
    unrar
    file
    powertop
    htop
    bottom
    openconnect
    networkmanager-openconnect
    bluetuith

    # other utilities
    quickemu
    waypipe
    distrobox
    docker-compose
    # hledger

    ## programming languages
    uv
    swig
    (pkgs.python3.withPackages (ps:
      with ps; [
        pip
        ipython
        matplotlib
        jupyterlab
        setuptools
        pytest
      ]))
    gnumake
    gcc
    ghc
    nodejs
    # cmakeWithGui
    # shellcheck
    # quarto

    ## latex
    texlive.combined.scheme-full
    typst
  ];

  virtualisation = {
    # docker = {
    #   enable = true;
    #   rootless.enable = true;
    #   rootless.setSocketVariable = true;
    # };
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    libvirtd.enable = true;
    # waydroid.enable = true;
    # waydroid.package = pkgs.waydroid-nftables;
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}
