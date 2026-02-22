{
  description = "My neovim flake using nixCats";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixCats.url = "github:BirdeeHub/nixCats-nvim";

    "plugins-org-bullets" = {
      url = "github:nvim-orgmode/org-bullets.nvim";
      flake = false;
    };
    # "plugins-bruno" = {
    #   url = "github:romek-codes/brun.nvim";
    #   flake = false;
    # };
    "plugins-himalaya-ui" = {
      url = "github:aliyss/vim-himalaya-ui";
      flake = false;
    };
    "plugins-everforest" = {
      url = "github:neanias/everforest-nvim";
      flake = false;
    };
  };
  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    inherit (inputs.nixCats) utils;
    # forEachSystem = utils.eachSystem nixpkgs.lib.platforms.all;
    forEachSystem = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.all;
    pluginOverlay = utils.standardPluginOverlay inputs;
  in {
    packages = forEachSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [pluginOverlay];
        config = {};
      };
    in
      utils.mkAllWithDefault (import ./. (inputs // {inherit pkgs utils;})));
    homeModule = self.packages.x86_64-linux.default.homeModule;
    nixosModule = self.packages.x86_64-linux.default.nixosModule;
  };
}
