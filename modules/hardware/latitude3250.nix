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
        hardware.enableRedistributableFirmware = lib.mkDefault true;
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
      };
  };
}
