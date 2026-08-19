{ inputs, ... }:
{
  # `flake-file` reads `flake-file.inputs.X` from across the repo and merges
  # them into the top-level `inputs` attr of flake.nix on regeneration.
  flake-file.inputs.tinted-schemes = {
    url = "github:tinted-theming/schemes";
    flake = false;
  };

  flake-file.inputs.stylix = {
    url = "github:nix-community/stylix";
    inputs = {
      nixpkgs.follows = "nixpkgs";
      tinted-schemes.follows = "tinted-schemes";
    };
  };

  lix.stylix = {
    os = { lib, pkgs, config, ... }: {
      imports = [ inputs.stylix.nixosModules.stylix ];
      stylix = {
        enable = true;
        base16Scheme = "${config.stylix.inputs.tinted-schemes}/base16/catppuccin-mocha.yaml";
        polarity = "dark"; # mocha is dark; kept explicit for clarity

        fonts = {
          monospace = {
            package = pkgs.nerd-fonts.jetbrains-mono;
            name = "JetBrainsMono Nerd Font";
          };
          sansSerif = {
            package = pkgs.nerd-fonts.jetbrains-mono;
            name = "JetBrainsMono Nerd Font";
          };
          serif = {
            package = pkgs.dejavu_fonts;
            name = "DejaVu Serif";
          };
          emoji = {
            package = pkgs.noto-fonts-color-emoji;
            name = "Noto Color Emoji";
          };
          sizes = {
            desktop = 10;
            applications = 12;
            terminal = 12;
            popups = 10;
          };
        };

        cursor = {
          package = pkgs.kdePackages.breeze;
          name = "breeze_cursors";
          size = 24;
        };

        # icons.dark = "Papirus-Dark";

        targets = {
          gtk.enable = true; # GTK theme / css; backups forced above
          qt.enable = true;
        };
      };
    };
  };
}
