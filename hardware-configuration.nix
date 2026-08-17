{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.kernelParams = [
    "usbcore.autosuspend=-1"
    "panic=10"
    "oops=panic"
  ];

  boot.initrd.availableKernelModules = [
    "ahci"
    "ehci_pci"
    "usb_storage"
    "sd_mod"
    "sr_mod"
    "r8169"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [
    "kvm-intel"
    "tcp_bbr"
    "rtw88_8821cu"
    "rtw88_core"
    "rtw88_usb"
    "btusb"
  ];
  boot.extraModulePackages = [ ];

  boot.extraModprobeConfig = ''
    options zfs zfs_arc_min=268435456
    options zfs zfs_arc_max=1610612736
    options zfs zfs_compressed_arc_enabled=1
    options zfs zfs_arc_sys_free=536870912
  '';

  boot.supportedFilesystems = [ "btrfs" "zfs" ];

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;
  hardware.wirelessRegulatoryDatabase = true;

  networking.hostId = "8425e349";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
