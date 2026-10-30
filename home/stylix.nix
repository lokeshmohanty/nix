{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:
{
  imports = [
    inputs.stylix.homeModules.stylix
  ];

  options = {
    stylixConfig = {
      enable = lib.mkEnableOption "enable stylix";
      theme = lib.mkOption { type = lib.types.str; };
    };
    wallpaper = lib.mkOption {
      type =
        with lib.types;
        oneOf [
          str
          path
          package
        ];
    };
  };
  config = lib.mkIf config.stylixConfig.enable {
    # wallpaper = with config.lib.stylix.colors.withHashtag;
    #   pkgs.runCommand "cat.png" {} ''
    #     pastel=${pkgs.pastel}/bin/pastel
    #     SHADOWS=$($pastel darken 0.1 '${base05}' | $pastel format hex)
    #     TAIL=$($pastel lighten 0.1 '${base02}' | $pastel format hex)
    #     HIGHLIGHTS=$($pastel lighten 0.1 '${base05}' | $pastel format hex)

    #     ${pkgs.imagemagick}/bin/convert ${./attachments/basecat.png} \
    #       -fill '${base00}' -opaque black \
    #       -fill '${base05}' -opaque white \
    #       -fill '${base08}' -opaque blue \
    #       -fill $SHADOWS -opaque gray \
    #       -fill '${base02}' -opaque orange \
    #       -fill $TAIL -opaque green \
    #       -fill $HIGHLIGHTS -opaque brown \
    #       $out'';
    stylix = {
      enable = true;
      targets = {
        firefox.enable = false;
        tofi.enable = false;
        rofi.enable = false;
      };
      polarity = "dark";
      # opacity = {
      #   applications = 0.8;
      #   desktop = 0.8;
      #   popups = 0.8;
      #   terminal = 0.4;
      # };
      image = config.wallpaper;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/${config.stylixConfig.theme}.yaml";
      icons = {
        enable = true;
        package = pkgs.papirus-icon-theme; # material-design-icons;
        dark = "papirus-icon-theme"; # "material-design-icons";
        light = "papirus-icon-theme"; # "material-design-icons";
      };
      cursor = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Ice";
        size = 24;
      };
      fonts = {
        serif = config.stylix.fonts.monospace;
        sansSerif = config.stylix.fonts.monospace;
        monospace = {
          package = pkgs.cascadia-code;
          name = config.vars.fontName;
        };
        emoji = {
          package = pkgs.noto-fonts-color-emoji;
          name = "Noto Color Emoji";
        };
        sizes = {
          applications = 12;
          desktop = 10;
          popups = 10;
          terminal = 14;
        };
      };
    };
  };
}
