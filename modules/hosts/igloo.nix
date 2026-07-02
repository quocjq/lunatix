{
  # host aspect
  den.aspects.igloo = {den}: {
    includes = [
      den.aspect.doom-emacs
    ];
    # host NixOS configuration
    nixos =
      { config, pkgs, lib, modulesPath, ... }:
      {
        imports =
          [ (modulesPath + "/installer/scan/not-detected.nix")
          ];

        boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "ahci" "nvme" "ums_realtek" "usb_storage" "sd_mod" ];
        boot.initrd.kernelModules = [ ];
        boot.kernelModules = [ "kvm-intel" ];
        boot.extraModulePackages = [ ];

        fileSystems."/" =
          { device = "/dev/mapper/luks-4775eff2-bc10-4918-8bb7-c64e35958085";
            fsType = "btrfs";
          };

        boot.initrd.luks.devices."luks-4775eff2-bc10-4918-8bb7-c64e35958085".device = "/dev/disk/by-uuid/4775eff2-bc10-4918-8bb7-c64e35958085";

        fileSystems."/home" =
          { device = "/dev/mapper/luks-4775eff2-bc10-4918-8bb7-c64e35958085";
            fsType = "btrfs";
            options = [ "subvol=home" ];
          };

        fileSystems."/nix" =
          { device = "/dev/mapper/luks-4775eff2-bc10-4918-8bb7-c64e35958085";
            fsType = "btrfs";
            options = [ "subvol=nix" ];
          };

        fileSystems."/boot" =
          { device = "/dev/disk/by-uuid/3E11-FD36";
            fsType = "vfat";
            options = [ "fmask=0077" "dmask=0077" ];
          };

        swapDevices =
          [ { device = "/dev/mapper/luks-1b8f30e4-ac2d-4ed1-b038-35cd76493e2a"; }
          ];

        nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
        hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
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
	fonts.packages = with pkgs; [
	  jetbrains-mono
	  fira-code
	  symbola
	  nerd-fonts.jetbrains-mono
	  noto-fonts-cjk-sans
	  noto-fonts-color-emoji
	];

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
