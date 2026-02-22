{
  lib,
  config,
  ...
}: {
  # programs.ssh.startAgent = true;
  options.sshServer.enable = lib.mkEnableOption "enable ssh server";
  config = lib.mkIf config.sshServer.enable {
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = true;
        PermitRootLogin = "no";
        X11Forwarding = true;
      };
    };
  };
}
