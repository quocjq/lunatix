{
  # host aspect
  den.aspects.igloo = {
    # host NixOS configuration
    nixos =
      { pkgs, ... }:
      {
	imports = [ ./_nixos/hardware-configuration.nix ];

        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;
        boot.kernelPackages = pkgs.linuxPackages_latest;

        boot.initrd.luks.devices."luks-1b8f30e4-ac2d-4ed1-b038-35cd76493e2a".device =
          "/dev/disk/by-uuid/1b8f30e4-ac2d-4ed1-b038-35cd76493e2a";

        networking.hostName = "nixos";
        networking.networkmanager.enable = true;

        nix.settings.experimental-features = [ "nix-command" "flakes" "pipe-operators" ];

        time.timeZone = "Asia/Ho_Chi_Minh";

        i18n.defaultLocale = "en_US.UTF-8";
        i18n.extraLocaleSettings = {
          LC_ADDRESS = "vi_VN";
          LC_IDENTIFICATION = "vi_VN";
          LC_MEASUREMENT = "vi_VN";
          LC_MONETARY = "vi_VN";
          LC_NAME = "vi_VN";
          LC_NUMERIC = "vi_VN";
          LC_PAPER = "vi_VN";
          LC_TELEPHONE = "vi_VN";
          LC_TIME = "vi_VN";
        };

        services.xserver.enable = true;
        services.displayManager.sddm.enable = true;
        services.desktopManager.plasma6.enable = true;
        services.xserver.xkb = {
          layout = "us";
          variant = "";
        };

        services.printing.enable = true;

        services.pulseaudio.enable = false;
        security.rtkit.enable = true;
        services.pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
        };

        programs.firefox.enable = true;

        nixpkgs.config.allowUnfree = true;

        environment.systemPackages = with pkgs; [
          neovim
          wget
          git
          curl
	  emacs
	  obsidian
        ];
      };

    # host provides default home environment for its users
    provides.to-users.homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.vim ];
      };
  };
}
