{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations = {
    bhaskara = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs self;};
      modules = [
        inputs.nixos-hardware.nixosModules.common-cpu-intel
        inputs.musnix.nixosModules.musnix
        ./configuration.nix
        ./hardware-configuration.nix
        ./syncthing.nix
      ];
    };
  };
  flake.homeConfigurations = {
    "lokesh@bhaskara" = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
      extraSpecialArgs = {inherit inputs self;};
      modules = [./home.nix];
    };
  };
}
