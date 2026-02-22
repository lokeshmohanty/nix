{pkgs, ...}: {
  fonts = {
    fontDir.enable = true;
    enableDefaultPackages = true;
    packages = with pkgs; [
      iosevka-comfy.comfy-duo
      nerd-fonts.inconsolata-go
      nerd-fonts.fira-code
      cascadia-code
      victor-mono
      google-fonts
      font-awesome
    ];
  };
}
