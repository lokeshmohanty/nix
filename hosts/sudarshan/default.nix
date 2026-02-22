{
  self,
  inputs,
  ...
}: {
  flake.nixosConfigurations = {
    sudarshan = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs self;};
      modules = [
        inputs.nixos-hardware.nixosModules.lenovo-thinkpad-l14-amd
        inputs.musnix.nixosModules.musnix
        ./configuration.nix
        ./hardware-configuration.nix
        # ./syncthing.nix
      ];
    };
  };
  flake.homeConfigurations = {
    "lokesh@sudarshan" = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
      extraSpecialArgs = {inherit inputs self;};
      modules = [./home.nix];
    };
  };
}
