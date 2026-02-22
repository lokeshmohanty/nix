{
  self,
  inputs,
  ...
}: {
  flake.homeConfigurations = {
    "lokesh@server" = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
      extraSpecialArgs = {inherit inputs self;};
      modules = [./home.nix];
    };
  };
}
