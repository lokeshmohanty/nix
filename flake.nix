{
  description = "Lokesh's NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    hyprland.url = "github:hyprwm/Hyprland";

    nixos-hardware.url = "github:NixOS/nixos-hardware";
    musnix.url = "github:musnix/musnix";

    nix-alien.url = "github:thiagokokada/nix-alien";
    stylix.url = "github:danth/stylix";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    # nvim.url = "github:lokeshmohanty/nix-config?dir=modules/nvim";
    nvim.url = "./modules/nvim";
    nvim.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {flake-parts, ...} @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];
      # import home-manager to export flake.homeConfigurations and flake.homeModules
      imports = [./hosts inputs.home-manager.flakeModules.home-manager];
      perSystem = {pkgs, ...}: {
        # packages = import ./pkgs {inherit pkgs inputs;};
        formatter = pkgs.alejandra;
      };
    };
}
