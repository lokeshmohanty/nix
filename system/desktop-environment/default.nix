{ pkgs, ... }:
{
  imports = [
    ./display-manager.nix

    # window manager
    ./hyprland.nix
    ./niri.nix

    # quick shell
    ./noctalia.nix
  ];

  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  services.gnome.sushi.enable = true; # nautilus file previewer

  programs.gpu-screen-recorder.enable = true;
  programs.nautilus-open-any-terminal.enable = true;
  programs.nautilus-open-any-terminal.terminal = "${pkgs.kitty}/bin/kitty --single-instance";
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
  };

  environment.sessionVariables.GSETTINGS_SCHEMA_DIR = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}/glib-2.0/schemas";
  environment.systemPackages = with pkgs; [
    glib
    gsettings-desktop-schemas
    xdg-desktop-portal

    brightnessctl
    pinentry-qt
    libnotify
    wl-clipboard
    wtype
    pamixer
    wlr-randr
    ntfs3g

    # screenshot
    grim
    slurp
    satty # configured in home-manager
    tesseract

    graphviz
    qt5.qtwayland
    qt6.qtwayland
    papirus-icon-theme

    # howdy
    pavucontrol # manage audio
    nwg-displays # manage monitors
    nwg-look # manage gtk
    qalculate-qt # calculator
    nautilus # file manager
    ffmpegthumbnailer
    mpv # media player
    imv # image viewer
    gimp # image editor
    kdePackages.okular # pdf viewer
    kdePackages.gwenview # image viewer
    # kdePackages.kdenlive
  ];
}
