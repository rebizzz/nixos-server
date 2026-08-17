# Do not modify this file manually!
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Disable USB autosuspend — keeps Realtek USB Wi-Fi dongle permanently awake
  boot.kernelParams = [
    "usbcore.autosuspend=-1"
    "panic=10"   # Auto-reboot 10s after kernel panic (headless resilience)
    "oops=panic" # Treat kernel oops as panic
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

  # ZFS ARC tuning — cap at 1.5GB to prevent OOM on 4-8GB RAM systems
  boot.extraModprobeConfig = ''
    options zfs zfs_arc_min=268435456
    options zfs zfs_arc_max=1610612736
    options zfs zfs_compressed_arc_enabled=1
    options zfs zfs_arc_sys_free=536870912
  '';

  # Filesystems
  boot.supportedFilesystems = [ "btrfs" "zfs" ];

  # Non-free firmware (required for Realtek USB Wi-Fi rtw88 + Intel microcode)
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;
  hardware.wirelessRegulatoryDatabase = true;

  # Host ID required for ZFS pool import safety
  networking.hostId = "8425e349";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
