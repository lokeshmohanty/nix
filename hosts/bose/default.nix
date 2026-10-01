{
  self,
  inputs,
  ...
}:
{
  flake.nixosConfigurations = {
    bose = self.hostlib.mkNixosHost {
      hardwareModules = [ inputs.nixos-hardware.nixosModules.common-cpu-intel ];
      extraModules = [
        ./configuration.nix
        ./hardware-configuration.nix
        ./syncthing.nix
      ];
    };
  };
  flake.homeConfigurations = {
    "lokesh@bose" = self.hostlib.mkHomeHost (
      { pkgs, ... }:
      {
        imports = [ ../../home ];

        modules = {
          ai.enable = true;
          activations.enable = true;
          editor.enable = true;
          gui.enable = true;
          shell.enable = true;
          tui.enable = true;
        };

        home.packages = with pkgs; [ slack wayvnc wlvncc];
      }
    );
  };
}
