{
  pkgs,
  utils,
  ...
}: let
  # path to your new .config/nvim
  luaPath = ./.;

  # see :help nixCats.flake.outputs.categories
  categoryDefinitions = {
    pkgs,
    settings,
    categories,
    extra,
    name,
    mkPlugin,
    ...
  } @ packageDef: {
    lspsAndRuntimeDeps = {
      general = with pkgs; [
        lua-language-server
        stylua

        nixd
        alejandra

        python3Packages.python-lsp-server
        tinymist
        rust-analyzer
        tree-sitter # for treesitter
        trashy # for Snacks.Explorer
        mermaid-cli
        ghostscript # for Snacks.Image
      ];
    };

    # This is for plugins that will load at startup without using packadd:
    startupPlugins = {
      general = with pkgs.vimPlugins; [
        lze # lazy-load plugins
        vim-sleuth # heuristically set buffer options
        vim-slime # send text to live repl
        Recover-vim # add compare action for swap files

        snacks-nvim
        mini-nvim
        neogit
        noice-nvim

        nvim-lspconfig
        blink-cmp
        nvim-treesitter.withAllGrammars

        lualine-nvim
        lualine-lsp-progress
        gitsigns-nvim
        which-key-nvim
        render-markdown-nvim
        markdown-preview-nvim

        vimtex

        orgmode
        org-roam-nvim
        zk-nvim

        nvim-lint
        conform-nvim
        nvim-dap
        nvim-dap-view
        nvim-dap-virtual-text
        # nvim-nio

        pkgs.neovimPlugins.everforest
      ];
    };

    # not loaded automatically at startup.
    # use with packadd and an autocommand in config to achieve lazy loading
    optionalPlugins = {
      general = with pkgs.vimPlugins; [
        lazydev-nvim
        vim-startuptime
        typst-preview-nvim
        copilot-lua
        CopilotChat-nvim

        nvim-dap-python
        pkgs.neovimPlugins.org-bullets

        grug-far-nvim
        gx-nvim
        flash-nvim # jump

        undotree
        pkgs.neovimPlugins.himalaya-ui
      ];
    };
  };

  # see :help nixCats.flake.outputs.packageDefinitions
  packageDefinitions = rec {
    nvim = {
      pkgs,
      name,
      mkPlugin,
      ...
    }: {
      settings = {
        suffix-path = true;
        suffix-LD = true;
        aliases = ["vi"];
        configDirName = "nvim";
        hosts.python3.enable = true;
        hosts.node.enable = true;
        hosts.ruby.enable = false;
        hosts.perl.enable = false;
      };
      categories = {general = true;};
      extra = {};
    };
    vi = nvim // {settings.wrapRC = false;};
  };

  # We will build the one named nvim here and export that one.
  defaultPackageName = "nvim";
  # return our package!
in
  utils.baseBuilder luaPath {inherit pkgs;} categoryDefinitions packageDefinitions defaultPackageName
# NOTE: or to return a set of all of them:
# `in utils.mkAllPackages (utils.baseBuilder luaPath { inherit pkgs; } categoryDefinitions packageDefinitions defaultPackageName)`

