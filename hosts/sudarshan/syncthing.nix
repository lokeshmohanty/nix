{...}: {
  services.syncthing = {
    enable = true;
    user = "lokesh";
    openDefaultPorts = true;
    overrideDevices = true;
    overrideFolders = true;
    dataDir = "/home/lokesh/.local/syncthing";
    settings = {
      devices = {
        "lab" = {
          id = "BKTCSPE-QCLARTR-5UVN7OB-NRHFAJI-SG36GWR-6NDDDO7-FLQVPV6-MGIU6AT";
          # autoAcceptFolders = true;
        };
        "phone" = {
          id = "KITNSPR-KMBOSUP-RLJS4XX-KILL76P-SR3HAEL-VKQR4U3-JN636OM-FXNZ3AX";
          # autoAcceptFolders = true;
        };
      };
      folders = {
        "Projects" = {
          path = "/home/lokesh/Projects";
          devices = ["lab"];
          ignorePatterns = [".venv/*"];
        };
        "Research" = {
          path = "/home/lokesh/Documents/Research";
          devices = ["lab"];
          ignorePatterns = [".venv/*"];
        };
        "Presentations" = {
          path = "/home/lokesh/Documents/Presentations";
          devices = ["lab"];
          ignorePatterns = [".venv/*"];
        };
        "Books" = {
          path = "/home/lokesh/Documents/Books";
          devices = ["lab"];
          ignorePatterns = [".venv/*"];
        };
        "Practice" = {
          path = "/home/lokesh/Desktop/Practice";
          devices = ["lab"];
          ignorePatterns = [".venv/*"];
        };
        "Org" = {
          path = "/home/lokesh/Documents/Org";
          devices = ["phone" "lab"];
          ignorePatterns = [".venv/*"];
        };
        "Notebook" = {
          path = "/home/lokesh/Documents/Notebook";
          devices = ["phone" "lab"];
          ignorePatterns = [".venv/*"];
        };
        "Personal" = {
          path = "/home/lokesh/Documents/Personal";
          devices = ["phone"];
        };
        "Camera" = {
          path = "/home/lokesh/Pictures/Phone";
          devices = ["phone"];
        };
      };
    };
  };
}
