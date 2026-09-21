{ ... }:
{
  services.syncthing = {
    enable = true;
    user = "lokesh";
    openDefaultPorts = true;
    overrideDevices = true;
    overrideFolders = true;
    dataDir = "/home/lokesh/.local/syncthing";
    settings = {
      devices.lab.id = "JMX5I5E-QPGGDMS-MWEE6FN-JPZXFHK-EJFSXVH-5FGKYBP-XXOR5VT-2LOB7AS";
      folders = {
        "Projects" = {
          path = "/home/lokesh/Projects";
          devices = [
            "lab"
          ];
          ignorePatterns = [
            ".venv/*"
            ".direnv/*"
            "target/*"
            "shell/*"
            "node_modules/*"
            ".output/*"
          ];
        };
        "Research" = {
          path = "/home/lokesh/Documents/Research";
          devices = [
            "lab"
          ];
          ignorePatterns = [
            ".venv/*"
            ".direnv/*"
            "node_modules/*"
            ".output/*"
          ];
        };
        "Presentations" = {
          path = "/home/lokesh/Documents/Presentations";
          devices = [
            "lab"
          ];
          ignorePatterns = [
            ".venv/*"
            ".direnv/*"
            "node_modules/*"
            ".output/*"
          ];
        };
        "Practice" = {
          path = "/home/lokesh/Desktop/Practice";
          devices = [
            "lab"
          ];
          ignorePatterns = [
            ".venv/*"
            ".direnv/*"
            "node_modules/*"
            ".output/*"
          ];
        };
        "Notebook" = {
          path = "/home/lokesh/Documents/Notebook";
          devices = [
            "lab"
          ];
          ignorePatterns = [
            ".venv/*"
            ".direnv/*"
            "node_modules/*"
            ".output/*"
          ];
        };
        # "Personal" = {
        #   path = "/home/lokesh/Documents/Personal";
        #   devices = [ "phone" ];
        # };
      };
    };
  };
}
