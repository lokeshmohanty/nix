{
  self,
  inputs,
  ...
}:
{
  flake.nixosConfigurations = {
    bhaskara = self.hostlib.mkNixosHost {
      hardwareModules = [ inputs.nixos-hardware.nixosModules.common-cpu-intel ];
      extraModules = [
        ./configuration.nix
        ./hardware-configuration.nix
      ];
    };
  };
  flake.homeConfigurations = {
    "lokesh@bhaskara" = self.hostlib.mkHomeHost (
      { pkgs, ... }:
      {
        imports = [
          ../../home
          ./email.nix
          (import ../../home/services/syncthing.nix {
            device = "laptop";
            deviceId = "ZUAVAEV-LA24HLW-EIXNXCB-O7DEVOB-CJWPE22-SH5JKJY-MYCOLMN-EUK5LAS";
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
        home.packages = with pkgs; [ slack wayvnc wlvncc nvtopPackages.nvidia ];
      }
    );
  };
}
