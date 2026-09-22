{
  pkgs,
  ...
}:
{
  programs.dconf.enable = true;
  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-egui;
    enableSSHSupport = true;
  };
  programs.fish.enable = true;
  programs.git = {
    enable = true;
    config = {
      init.defaultBranch = "main";
      pull.rebase = true;
      user = {
        email = "lokesh1197@gmail.com";
        name = "Lokesh Mohanty";
      };
    };
  };
  # programs.virt-manager.enable = true;
}
