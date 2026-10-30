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
      ];
    };
  };
  flake.homeConfigurations = {
    "lokesh@bose" = self.hostlib.mkHomeHost (
      { pkgs, ... }:
      {
        imports = [
          ../../home
          (import ../../home/services/syncthing.nix {
            device = "laptop";
            deviceId = "E35GV3M-GT4AQEH-DEWAIYP-T6MSAM4-UFC7U4C-PWQHMSM-6XGZW5P-62VIKQM";
            address = "tcp://100.127.108.81:22000";
            folders = [
              "Projects"
              "Research"
              "Presentations"
              "Books"
              "Practice"
              "Notebook"
            ];
          })
        ];

        modules = {
          ai.enable = true;
          activations.enable = true;
          editor.enable = true;
          gui.enable = true;
          shell.enable = true;
          tui.enable = true;
        };

        home.packages = with pkgs; [ slack wayvnc wlvncc ];
      }
    );
  };
}
