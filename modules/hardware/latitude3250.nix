{ inputs, ... }:
{
  den.aspects.latitude3250 = {
    nixos =
      {
        config,
        pkgs,
        lib,
        modulesPath,
        ...
      }:
      {
        imports = [
          (modulesPath + "/installer/scan/not-detected.nix")
        ];

        boot.initrd.availableKernelModules = [
          "xhci_pci"
          "thunderbolt"
          "ahci"
          "nvme"
          "ums_realtek"
          "usb_storage"
          "sd_mod"
        ];
        boot.initrd.kernelModules = [ ];
        boot.kernelModules = [ "kvm-intel" ];
        boot.extraModulePackages = [ ];
        boot.kernelPackages = pkgs.linuxPackages_latest;

      };
  };
}
