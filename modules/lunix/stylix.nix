{ inputs, ... }:
{
  # `flake-file` reads `flake-file.inputs.X` from across the repo and merges
  # them into the top-level `inputs` attr of flake.nix on regeneration.
  flake-file.inputs.stylix = {
    url = "github:nix-community/stylix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  lix.stylix = {
    os = { pkgs, ... }: {
      imports = [ inputs.stylix.nixosModules.stylix ];
    };

    provides.to-hosts.homeManager = { pkgs, ... }: {
      imports = [ inputs.stylix.homeModules.stylix ];

      stylix = {
        enable = true;

        # Single source of truth for the palette. Image-derived from the
        # wallpaper committed at modules/lunix/themes/wallpaper.jpg.
        image = ./themes/wallpaper.jpg;

        polarity = "dark";   # everything currently uses a dark theme

        fonts = {
          monospace = {
            package = pkgs.nerd-fonts.jetbrains-mono;
            name    = "JetBrainsMono Nerd Font";
          };
          sansSerif = {
            package = pkgs.nerd-fonts.jetbrains-mono;
            name    = "JetBrainsMono Nerd Font";
          };
          serif = {
            package = pkgs.dejavu_fonts;
            name    = "DejaVu Serif";
          };
          emoji = {
            package = pkgs.noto-fonts-emoji;
            name    = "Noto Color Emoji";
          };
          sizes = {
            desktop      = 10;
            applications = 12;
            terminal     = 12;
            popups       = 10;
          };
        };

        cursor = {
          package = pkgs.kdePackages.breeze;
          name    = "breeze_cursors";
          size    = 24;
        };

        icons = {
          enable  = true;
          package = pkgs.papirus-icon-theme;
        };

        targets = {
          hyprland.enable = true; # borders, shadows, groupbar, bg
          kde.enable      = true; # Plasma colors / fonts / cursor / wallpaper
          gtk.enable      = true;
          qt.enable       = true;
          # emacs: deliberately off. Doom Emacs overrides the theme and the
          # user wants doom-monokai-octagon preserved.
        };
      };
    };
  };
}
