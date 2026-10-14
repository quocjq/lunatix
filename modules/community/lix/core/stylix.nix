{ inputs, ... }:
{
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
    maid =
      { pkgs, config, ... }:
      {
        file.xdg_config."gtk-3.0/settings.ini" = {
          text = ''
            [Settings]
            gtk-application-prefer-dark-theme=1
            gtk-theme-name=adw-gtk3-dark
            gtk-icon-theme-name=breeze-dark
            gtk-cursor-theme-name=breeze_cursors
            gtk-cursor-theme-size=24
            gtk-font-name=JetBrainsMono Nerd Font 12
          '';
        };

        file.xdg_config."gtk-4.0/settings.ini" = {
          text = ''
            [Settings]
            gtk-application-prefer-dark-theme=1
            gtk-icon-theme-name=breeze-dark
            gtk-cursor-theme-name=breeze_cursors
            gtk-cursor-theme-size=24
            gtk-font-name=JetBrainsMono Nerd Font 12
          '';
        };

        # Fixes Zen Browser and Electron apps that read
        # color-scheme from the XDG portal instead of GTK
        file.xdg_config."xdg-desktop-portal/settings.conf" = {
          text = ''
            [org.freedesktop.appearance]
            color-scheme=1
          '';
        };
      };
    os =
      {
        lib,
        pkgs,
        config,
        ...
      }:
      {
        imports = [ inputs.stylix.nixosModules.stylix ];

        programs.dconf.enable = true;
        environment.systemPackages = with pkgs; [
          kdePackages.breeze
          kdePackages.breeze-gtk
          kdePackages.breeze-icons
          adw-gtk3
          adwaita-icon-theme
          adwaita-fonts
        ];
        stylix = {
          enable = true;
          base16Scheme = "${config.stylix.inputs.tinted-schemes}/base16/catppuccin-mocha.yaml";
          polarity = "dark";

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

          icons = {
            enable = true;
            dark = "breeze-dark";
            package = pkgs.kdePackages.breeze-icons;
          };

          targets = {
            gtk.enable = true; # GTK theme / css; backups forced above
            qt.enable = true;
          };
        };
      };
  };
}
