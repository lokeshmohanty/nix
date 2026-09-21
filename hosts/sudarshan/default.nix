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
        ./syncthing.nix
      ];
    };
  };
  flake.homeConfigurations = {
    "lokesh@sudarshan" = self.hostlib.mkHomeHost (
      { pkgs, ... }:
      {
        imports = [ ../../home ./email.nix ];

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
          tigervnc
          bitwarden-desktop
        ];
      }
    );
  };
}
