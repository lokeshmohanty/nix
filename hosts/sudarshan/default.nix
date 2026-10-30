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
            deviceId = "JMX5I5E-QPGGDMS-MWEE6FN-JPZXFHK-EJFSXVH-5FGKYBP-XXOR5VT-2LOB7AS";
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
