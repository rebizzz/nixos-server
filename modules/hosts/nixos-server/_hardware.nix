{
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.kernelParams = [
    "usbcore.autosuspend=-1"
    "panic=10"
    "oops=panic"
    # ARC sized for this box's actual 1.8 GiB RAM, leaving headroom for Docker/Jellyfin.
    "zfs.zfs_arc_min=268435456" # 256 MiB
    "zfs.zfs_arc_max=805306368" # 768 MiB
    "zfs.zfs_arc_sys_free=268435456" # 256 MiB headroom
  ];

  boot.initrd.availableKernelModules = [
    "ahci"
    "ehci_pci"
    "usb_storage"
    "sd_mod"
    "sr_mod"
    "r8169"
  ];
  boot.initrd.kernelModules = [];
  boot.kernelModules = [
    "kvm-intel"
    "tcp_bbr"
    "rtw88_8821cu"
    "rtw88_core"
    "rtw88_usb"
    "btusb"
  ];
  boot.extraModulePackages = [];

  boot.supportedFilesystems = ["btrfs" "zfs"];

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;
  hardware.wirelessRegulatoryDatabase = true;

  networking.hostId = "8425e349";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
