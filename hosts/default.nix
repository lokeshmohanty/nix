{
  self,
  inputs,
  ...
}:
let
  hostlib = rec {
    mkHomeHost =
      module:
      inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = { inherit inputs self; };
        modules = [ module ];
      };

    mkNixosHost =
      {
        hardwareModules ? [ ],
        extraModules ? [ ],
      }:
      inputs.nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs self; };
        modules = [
          inputs.determinate.nixosModules.default
          inputs.musnix.nixosModules.musnix
        ]
        ++ hardwareModules
        ++ extraModules;
      };
  };
in
{
  flake.hostlib = hostlib;

  imports = [
    ./sudarshan
    ./bhaskara
    ./bose
    ./server.nix
  ];
}
