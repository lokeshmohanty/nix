{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
{
  imports = [ inputs.ecr.homeManagerModules.default ];
  home.packages = with pkgs; [
    (isync.override { withCyrusSaslXoauth2 = true; })
    msmtp
    notmuch
  ];

  programs.ecr = {
    enable = true;
    desktop = true;
    server = {
      enable = true;
      bind = "0.0.0.0:8383";
    };
  };

  systemd.user.services.ecr-sync-dav = {
    Unit = {
      Description = "Fetch contacts and calendars into ecr's vdir";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${lib.getExe config.programs.ecr.package} account sync-dav";
    };
  };

  systemd.user.timers.ecr-sync-dav = {
    Unit.Description = "Fetch contacts and calendars into ecr's vdir";
    Timer = {
      OnCalendar = "*:0/15";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
