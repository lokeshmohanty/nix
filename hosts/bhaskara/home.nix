{config, ...}: {
  imports = [../../home];
  programs.rclone = {
    enable = true;
    remotes = {
      "archimedes" = {
        config = {
          type = "sftp";
          host = "10.24.36.22";
          user = "lokesh";
          key_file = "${config.home.homeDirectory}/.ssh/id_ed25519";
        };
        mounts."projects" = {
          enable = true;
          mountPoint = "${config.home.homeDirectory}/Remotes/archimedes";
        };
      };
    };
  };
}
