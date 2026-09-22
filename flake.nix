{
  description = "Lokesh's NixOS Configuration";

  nixConfig = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [ "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=" ];
  };

  inputs = {
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    hyprland.url = "github:hyprwm/Hyprland";

    sysc-greet = {
      url = "github:Nomadcxx/sysc-greet";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware";
    musnix.url = "github:musnix/musnix";

    llm-agents.url = "github:numtide/llm-agents.nix";

    # Tracks `main`. `github:lokeshmohanty/ecr/release` is the other channel and
    # follows the newest tag; `nix flake update ecr` moves whichever is pinned
    # here, and `ecr --version` reports the revision so the two never blur.
    ecr = {
      url = "github:lokeshmohanty/ecr";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-alien.url = "github:thiagokokada/nix-alien";
    nix-wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";
    nix-wrapper-modules.inputs.nixpkgs.follows = "nixpkgs";
    stylix.url = "github:danth/stylix";
    stylix.inputs.nixpkgs.follows = "nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    "plugins-slimline" = {
      url = "github:sschleemilch/slimline.nvim";
      flake = false;
    };
    "plugins-everforest" = {
      url = "github:neanias/everforest-nvim";
      flake = false;
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      imports = [
        ./hosts
        # required to export flake.homeConfigurations and flake.homeModules
        inputs.home-manager.flakeModules.home-manager
      ];

      perSystem =
        { pkgs, ... }:
        let
          packages = import ./pkgs { inherit pkgs inputs; };
          mkApp = name: drv: {
            type = "app";
            program =
              let
                main = drv.meta.mainProgram or name;
              in
              "${drv}/bin/${main}";
          };
          apps = builtins.mapAttrs mkApp packages;
        in
        {
          inherit packages apps;
          formatter = pkgs.nixfmt;
        };
    };
}
