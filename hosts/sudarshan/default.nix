{
  self,
  inputs,
  ...
}:
{
  flake.nixosConfigurations = {
    sudarshan = self.hostlib.mkNixosHost {
      hardwareModules = [ inputs.nixos-hardware.nixosModules.lenovo-thinkpad-l14-amd ];
      extraModules = [
        ./configuration.nix
        ./hardware-configuration.nix
      ];
    };
  };
  flake.homeConfigurations = {
    "lokesh@sudarshan" = self.hostlib.mkHomeHost (
      { pkgs, ... }:
      {
        imports = [
          ../../home
          inputs.ecr.homeManagerModules.default
          (import ../../home/services/syncthing.nix {
            device = "lab";
            deviceId = "CAV5U6J-K62NA3F-RDJ2ONT-Y4X7K4F-6XKRDFP-ML34WGB-WBRBOLH-2GGAAAD";
            folders = [
              "Projects"
              "Research"
              "Presentations"
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

        home.packages = with pkgs; [
          slack
          wlvncc
          bitwarden-desktop
          nvtopPackages.amd
          faugus-launcher
        ];

        programs.ecr = {
          enable = true;
          desktop = true;
        };
      }
    );
  };
}
