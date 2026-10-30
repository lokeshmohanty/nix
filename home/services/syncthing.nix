# Shared syncthing home-manager module.
# Hosts call this function from their flake.homeConfigurations, passing their
# peer device info and the folder list to sync.
{
  device,
  deviceId,
  address ? null,
  folders,
}:
{ lib, ... }:
let
  # Common ignore pattern sets
  defaultIgnores = [
    ".venv/*"
    ".direnv/*"
    "node_modules/*"
    ".output/*"
  ];

  # Folder definitions: name -> { path, ignorePatterns }
  folderDefs = {
    "Projects" = {
      path = "/home/lokesh/Projects";
      ignorePatterns = defaultIgnores ++ [ "target/*" "shell/*" ];
    };
    "Research" = {
      path = "/home/lokesh/Documents/Research";
      ignorePatterns = defaultIgnores;
    };
    "Presentations" = {
      path = "/home/lokesh/Documents/Presentations";
      ignorePatterns = defaultIgnores;
    };
    "Books" = {
      path = "/home/lokesh/Documents/Books";
      ignorePatterns = defaultIgnores;
    };
    "Practice" = {
      path = "/home/lokesh/Desktop/Practice";
      ignorePatterns = defaultIgnores;
    };
    "Notebook" = {
      path = "/home/lokesh/Documents/Notebook";
      ignorePatterns = defaultIgnores;
    };
  };
in
{
  services.syncthing = {
    enable = true;
    overrideDevices = true;
    overrideFolders = true;
    settings = {
      devices = {
        ${device} = {
          id = deviceId;
          addresses = [ "dynamic" ] ++ lib.optional (address != null) address;
        };
      };
      folders = lib.genAttrs folders (name: folderDefs.${name} // { devices = [ device ]; });
    };
  };
}
