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
    os = { pkgs, ... }: {
      imports = [ inputs.stylix.nixosModules.stylix ];
    };

    provides.to-hosts.homeManager = { lib, pkgs, config, ... }: {
      imports = [ inputs.stylix.homeModules.stylix ];

      stylix = {
        enable = true;
        # Catppuccin Mocha base16. YAML from tinted-theming/schemes (the upstream
        # source stylix already consumes internally — pinned via our own input,
        # forwarded through stylix.inputs.tinted-schemes).
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

        icons.dark = "Papirus-Dark";

        targets = {
          hyprland.enable = true; # borders, shadows, groupbar, bg
          # hyprpaper disabled: stylix target writes `path = image`; null when no
          # image is set. Wallpaper is owned by noctalia runtime pool.
          # hyprpaper.enable = true;
          bat.enable = true;
          btop.enable = true;
          fzf.enable = true;
          ghostty.enable = true;
          kde.enable = true; # Plasma colors / fonts / cursor / wallpaper
          gtk.enable = true;
          qt.enable = true;
          nushell.enable = true;
          noctalia.enable = true;
          yazi.enable = true;
          starship.enable = true;
          mpv.enable = true;
          sioyek.enable = true;
          zen-browser.profileNames = [ "lunixose" ];
        };
      };
    };
  };
}
