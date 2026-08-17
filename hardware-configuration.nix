# Do not modify this file manually! Generated for nixos-server based on target hardware scan.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
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
    "rtw88_8821cu"
    "rtw88_core"
    "rtw88_usb"
    "btusb"
  ];
  boot.extraModulePackages = [ ];

  # Supported filesystems for Btrfs SSD and ZFS storage array
  boot.supportedFilesystems = [ "btrfs" "zfs" ];

  # Hardware firmware and wireless regulatory database
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.wirelessRegulatoryDatabase = true;

  # Hardware acceleration
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
    ];
  };

  # Host ID required for ZFS pool safety
  networking.hostId = "8425e349";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
