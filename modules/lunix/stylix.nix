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

    provides.to-hosts.homeManager = { lib, pkgs, ... }: {
      imports = [ inputs.stylix.homeModules.stylix ];

      stylix = {
        enable = true;
        image = ./themes/wallpaper.jpg;
        polarity = "dark"; # everything currently uses a dark theme

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

        icons.dark = "Papirus-Dark";

        targets = {
          hyprland.enable = true; # borders, shadows, groupbar, bg
          hyprpaper.enable = true;
          kde.enable = true; # Plasma colors / fonts / cursor / wallpaper
          gtk.enable = true;
          qt.enable = true;
          # emacs: deliberately off. Doom Emacs overrides the theme and the
          # user wants doom-monokai-octagon preserved.

          # noctalia v5 stylix target. Currently a no-op until
          # `programs.noctalia-shell` is loaded (the existing setup uses
          # v4's `programs.noctalia` in modules/lunix/hyprland/noctalia.nix).
          # Forward-compatible: activates once the v4 -> v5 migration lands.
          noctalia.enable = true;

          # yazi themes the file manager; needs lix.yazi to enable
          # `programs.yazi` first so a config file exists to theme.
          yazi.enable = true;

          # starship already enabled via lix.starship; stylix themes the TOML.
          starship.enable = true;
        };
      };
    };
  };
}
