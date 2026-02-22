{...}: {
  services.syncthing = {
    enable = true;
    user = "lokesh";
    openDefaultPorts = true;
    dataDir = "/home/lokesh/.local/syncthing";
    settings = {
      devices = {
        "laptop" = {
          id = "ZUAVAEV-LA24HLW-EIXNXCB-O7DEVOB-CJWPE22-SH5JKJY-MYCOLMN-EUK5LAS";
          autoAcceptFolders = true;
        };
        "phone" = {
          id = "KITNSPR-KMBOSUP-RLJS4XX-KILL76P-SR3HAEL-VKQR4U3-JN636OM-FXNZ3AX";
          autoAcceptFolders = true;
        };
      };
      folders = {
        "Projects" = {
          path = "/home/lokesh/Projects";
          devices = ["laptop"];
          ignorePatterns = [".venv/*"];
        };
        "Research" = {
          path = "/home/lokesh/Documents/Research";
          devices = ["laptop"];
          ignorePatterns = [".venv/*"];
        };
        "Presentations" = {
          path = "/home/lokesh/Documents/Presentations";
          devices = ["laptop"];
          ignorePatterns = [".venv/*"];
        };
        "Books" = {
          path = "/home/lokesh/Documents/Books";
          devices = ["laptop"];
          ignorePatterns = [".venv/*"];
        };
        "Practice" = {
          path = "/home/lokesh/Desktop/Practice";
          devices = ["laptop"];
          ignorePatterns = [".venv/*"];
        };
        "Org" = {
          path = "/home/lokesh/Documents/Org";
          devices = ["laptop" "phone"];
          ignorePatterns = [".venv/*"];
        };
        "Notebook" = {
          path = "/home/lokesh/Documents/Notebook";
          devices = ["laptop" "phone"];
          ignorePatterns = [".venv/*"];
        };
      };
    };
  };
}
