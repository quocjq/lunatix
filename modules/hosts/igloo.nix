{ __findFile, inputs, ... }: {
  den.hosts.x86_64-linux.igloo.users.lunixose = { };

  den.aspects.igloo = {
    includes = [
      <settings>
      <disko-desktop>
      <lig/agenix>
      <obs>
    ];

    disk = {
      name = "main";
      device = "/dev/disk/by-id/nvme-eui.01000000000000008ce38e0402c27c5c";
    };

    nixos =
      {
        config,
        pkgs,
        lib,
        modulesPath,
        ...
      }:
      {
        hardware.facter.reportPath = ../community/lix/hardware/latitude3250.json;
	hardware.graphics = {
	  enable = true;
	  enable32Bit = true; # Necessary if running 32-bit software/Steam games
	  extraPackages = with pkgs; [ 
	    intel-media-driver
	    intel-ocl 
	    intel-vaapi-driver    
	    vaapi-intel-hybrid
	    vpl-gpu-rt           # Required for QSV video runtime hooks on Tiger Lake+
	    intel-compute-runtime # OpenCL acceleration fallback
	 ];
	};
	environment.systemPackages = with pkgs; [
	  libglvnd  # Provides standard vendor-neutral OpenGL/EGL dispatch libraries
	];
        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;
        boot.kernelPackages = pkgs.linuxPackages_latest;
        age.rekey.hostPubkey = "/etc/ssh/ssh_host_ed25519_key.pub";
        # igloo builds on itself: derivation mode keeps rekeyed secrets out of
        # the repo (avoids the localStorageDir store-path write issue).
        age.rekey.storageMode = "derivation";

        nix.settings = {
          max-jobs = 1;
          cores = 2;
        };

        # nix-maid: user dotfiles are routed via the lix.* maid class into
        # users.users.<user>.maid; the den maid battery auto-imports the
        # nix-maid NixOS module when a user carries the "maid" class.
      };
  };
}
