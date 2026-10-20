{ inputs, ... }: {
  flake-file.inputs = {
    nvf = {
      url = "github:NotAShelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  lix.nvf = {
    os = {
      imports = [ inputs.nvf.nixosModules.default ];
      programs.nvf = {
        enable = true;
        settings = {
	  vim = {
            viAlias = true;
            vimAlias = true;
            lsp = {
              enable = true;
            };
	    language = {
	      nix.enable = true;
	      nu.enable = true;
	      markdown.enable = true;
	      astro.enable = true;
	    };
          };
        };
      };
    };
  };
}
