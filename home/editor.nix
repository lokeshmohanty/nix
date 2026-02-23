{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: {
  imports = [inputs.nvim.homeModule];

  home.packages = with pkgs; [pre-commit slides];
  home.activation.zk = lib.mkAfter ''
    ln -sf /home/lokesh/.nix/config/zk ${config.xdg.configHome}
  '';

  home.sessionVariables.EDITOR = "vi";
  home.sessionVariables.ZK_NOTEBOOK_DIR = "/home/lokesh/Documents/Notebook";
  nvim = {
    enable = true;
    packageNames = ["nvim"];
  };

  programs.zk = {
    enable = true;
    # settings = {
    #   notebook.dir = "~/Documents/Notebook/";
    #   note = {
    #     language = "en";
    #     default-title = "Untitled";
    #     filename = "{{id}}-{{slug title}}";
    #     extension = "md";
    #     template = "default.md"; # If not an absolute path, it is relative to .zk/templates/
    #     id-charset = "alphanum"; # The charset used for random IDs.
    #     id-length = 4; # Length of the generated random IDs.
    #     id-case = "lower"; # Letter case for the random IDs.
    #   };
    #   extra.author = "Lokesh Mohanty";
    #   group.journal = {
    #     paths = ["journal/weekly" "journal/daily"];
    #     note.filename = "{{format-date now}}";
    #   };
    #   format.markdown = {
    #     hashtags = true; # Enable support for #hashtags
    #     colon-tags = true; # Enable support for :colon:separated:tags:
    #   };
    #   tool = {
    #     editor = "nvim";
    #     shell = "fish";
    #     pager = "less -FIRX";
    #     fzf-preview = "bat -p --color always {-1}";
    #   };
    #   filter.recents = "--sort created- --created-after 'last two weeks'";
    #   alias = {
    #     edlast = "zk edit --limit 1 --sort modified- $argv";
    #     recent = "zk edit --sort created- --created-after 'last two weeks' --interactive";
    #     lucky = "zk list --quiet --format full --sort random --limit 1";
    #     ls = "zk edit --interactive";
    #     t = "zk edit --interactive --tag $argv";
    #     daily = "zk new --no-input \"$ZK_NOTEBOOK_DIR/journal\"";
    #     journal = "zk edit --sort created- journal --interactive";
    #     ni = "zk new --no-input \"$ZK_NOTEBOOK_DIR/ideas\" --title $argv";
    #     update = "cd $ZK_NOTEBOOK_DIR; git add -A; git commit -am 'update'; gith push; cd -";
    #     slides = "zk list --interactive --quiet --format path --delimiter0 $argv | xargs -0 slides";
    #     log = "zk list --quiet --format path --delimiter0 $argv | xargs -0 git log --patch --";
    #     wc = "zk list --format '{{word-count}}\t{{title}}' --sort word-count $argv";
    #   };
    #   lsp.diagnostics = {
    #     wiki-title = "hint";
    #     dead-link = "error";
    #     missing-backlink = { level = "warning"; position = "bottom"; };
    #   };
    # };
  };
}
