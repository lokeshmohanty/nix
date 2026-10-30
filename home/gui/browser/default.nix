{ pkgs, lib, config, ... }:
{
  options.modules.gui.browser.enable = lib.mkEnableOption "browser programs";

  config = lib.mkIf config.modules.gui.browser.enable {
    home.sessionVariables.BROWSER = "firefox";
    home.packages = [ pkgs.firefox ];
    programs.qutebrowser = {
      enable = true;
      loadAutoconfig = true;
      searchEngines = {
        DEFAULT = "https://www.google.com/search?hl=en&q={}";
        g = "https://www.google.com/search?hl=en&q={}";
        y = "https://youtube.com/results?search_query={}";
        ai = "https://www.perplexity.ai/search/new?q={}";
        ud = "https://www.urbandictionary.com/define.php?term={}";
      };
      settings = {
        auto_save.session = true;
        url.default_page = "qute://bookmarks";
        url.start_pages = [ "qute://bookmarks" ];
        content.autoplay = false;
      };
    };
  };
}
