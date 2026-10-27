{ pkgs, inputs, ... }:
let
  customPlugins = {
    slimline = pkgs.vimUtils.buildVimPlugin {
      pname = "slimline.nvim";
      version = "source";
      src = inputs.plugins-slimline;
      doCheck = false; # as slimline doesn't work at compile time
    };
    everforest = pkgs.vimUtils.buildVimPlugin {
      pname = "everforest-nvim";
      version = "source";
      src = inputs.plugins-everforest;
    };
  };
in
inputs.nix-wrapper-modules.wrappers.neovim.wrap [
  { inherit pkgs; }
  (
    { pkgs, ... }:
    {
      settings = {
        config_directory = "/home/lokesh/.config/nvim";
        aliases = [ "vi" ];
      };

      hosts.python3.nvim-host.enable = true;
      hosts.node.nvim-host.enable = true;
      hosts.ruby.nvim-host.enable = false;
      hosts.perl.nvim-host.enable = false;

      runtimePkgs = with pkgs; [
        lua-language-server
        stylua
        nixd
        nixfmt
        zuban
        tinymist
        rust-analyzer
        rustfmt
        haskell-language-server
        haskellPackages.cabal-fmt
        ormolu
        yaml-language-server
        typescript-language-server
        tailwindcss-language-server
        nginx-language-server
        bash-language-server
        helm-ls
        terraform-ls
        tree-sitter
        trashy
        mermaid-cli
        imagemagick
        texlab # LaTeX
        resvg # svg rendering for lean-nvim
      ];

      specs.general = {
        data = with pkgs.vimPlugins; [
          lze
          vim-sleuth
          vim-slime
          vim-nix
          Recover-vim
          plenary-nvim
          snacks-nvim
          mini-nvim
          neogit
          noice-nvim
          nvim-lspconfig
          blink-cmp
          nvim-treesitter.withAllGrammars
          customPlugins.slimline
          gitsigns-nvim
          which-key-nvim
          render-markdown-nvim
          markdown-preview-nvim
          img-clip-nvim
          # copilot-lua
          codecompanion-nvim
          claudecode-nvim
          vimtex
          nvim-lint
          conform-nvim
          nvim-dap
          nvim-dap-view
          nvim-dap-virtual-text
          customPlugins.everforest

          lean-nvim
          helm-ls-nvim
        ];
      };

      specs.optional = {
        lazy = true;
        data = with pkgs.vimPlugins; [
          lazydev-nvim
          vim-startuptime
          typst-preview-nvim
          zk-nvim
          nvim-dap-python
          grug-far-nvim
          gx-nvim
          flash-nvim
          undotree
        ];
      };
    }
  )
]
